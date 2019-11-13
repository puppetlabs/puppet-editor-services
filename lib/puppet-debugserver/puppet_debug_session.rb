# frozen_string_literal: true

module PuppetDebugServer
  # Manages a Puppet Debug session including features such as; breakpoints, flow control, hooks into puppet.
  class PuppetDebugSession
    # The hook manager class. This is responsible for adding and calling hooks.
    # @see PuppetDebugServer::Hooks
    # @return [PuppetDebugServer::Hooks]
    attr_reader :hook_manager

    # The hook handler class. This is responsible for responding to invoked hooks
    # @see PuppetDebugServer::DebugSession::HookHandlers
    # @return [PuppetDebugServer::DebugSession::HookHandlers]
    attr_reader :hook_handlers

    # The flow control class. This is responsible for controlling how the puppet agent execution flows. Including
    # cross thread flags, determining if a session is paused or terminating.
    # @see PuppetDebugServer::DebugSession::FlowControl
    # @return [PuppetDebugServer::DebugSession::FlowControl]
    attr_reader :flow_control

    # The Ruby ID (not Operating System Thread ID) of the thread running Puppet (as opposed to RPC Server or debug session)
    # @return [Integer]
    attr_reader :puppet_thread_id

    # The breakpoints class. This is responsible for storing and validation the active breakpoints during a debug session
    # @see PuppetDebugServer::DebugSession::BreakPoints
    # @return [PuppetDebugServer::DebugSession::BreakPoints]
    attr_reader :breakpoints

    # The session state class. This is responsible for determining the current and saved state of Puppet throughout the debug session
    # @see PuppetDebugServer::DebugSession::PuppetSessionState
    # @return [PuppetDebugServer::DebugSession::PuppetSessionState]
    attr_reader :puppet_session_state

    # Use to track the default instance of the debug session
    @@session_instance = nil # rubocop:disable Style/ClassVars  This class method (not instance) should be inherited

    VARIABLES_REFERENCE_TOP_SCOPE = 1
    ERROR_LOG_LEVELS = %i[warning err alert emerg crit].freeze

    # Creates a debug session
    def self.instance
      # This can be called from any thread
      return @@session_instance unless @@session_instance.nil? # rubocop:disable Style/ClassVars  This class method (not instance) should be inherited
      @@session_instance = PuppetDebugSession.new # rubocop:disable Style/ClassVars  This class method (not instance) should be inherited
    end

    def initialize
      @message_handler = nil
      @flow_control = PuppetDebugServer::DebugSession::FlowControl.new(self)
      @hook_manager = PuppetDebugServer::Hooks.new
      @hook_handlers = PuppetDebugServer::DebugSession::HookHandlers.new(self)
      @breakpoints = PuppetDebugServer::DebugSession::BreakPoints.new(self)
      @puppet_session_state = PuppetDebugServer::DebugSession::PuppetSessionState.new
      @evaluate_string_mutex = Mutex.new
    end

    # Executes a hook synchronously
    # @see PuppetDebugServer::DebugSession::HookHandlers
    # @param event_name [Symbol] The name of the hook to execute.
    # @param args [Array<Object>] The arguments of the hook
    def execute_hook(event_name, args)
      @hook_manager.exec_hook(event_name, args)
    end

    # Configures the debug session in it's initial state. Typically called as soon as the debug session is created
    def initialize_session
      # Save the thread incase we need to forcibly kill it
      @puppet_thread = Thread.current
      @puppet_thread_id = @puppet_thread.object_id.to_i
    end

    # Sends an OutputEvent to the Debug Client
    # @see DSP::OutputEvent
    # @param options [Hash] Options for the output
    def send_output_event(options)
      @message_handler.send_output_event(options) unless @message_handler.nil?
    end

    # Sends a StoppedEvent to the Debug Client
    # @see DSP::StoppedEvent
    # @param reason [String] Why the session has stopped
    # @param options [Hash] Options for the output
    def send_stopped_event(reason, options = {})
      @message_handler.send_stopped_event(reason, options) unless @message_handler.nil?
    end

    # Sends a ThreadEvent to the Debug Client
    # @see DSP::ThreadEvent
    # @param reason [String] Why the the thread status has changed
    # @param thread_id [Integer] The ID of the thread
    def send_thread_event(reason, thread_id)
      @message_handler.send_thread_event(reason, thread_id) unless @message_handler.nil?
    end

    # Sends an TerminatedEvent to the Debug Client to indicated the Debug Server is terminating
    # @see DSP::TerminatedEvent
    def send_termination_event
      @message_handler.send_termination_event unless @message_handler.nil?
    end

    # Sends an ExitedEvent to the Debug Client
    # @see DSP::ExitedEvent
    # @param exitcode [Integer] The exit code from the process. This is the puppet detailed exit code
    def send_exited_event(exitcode)
      @message_handler.send_exited_event(exitcode) unless @message_handler.nil?
    end

    # Sets up the debug session ready for actual use. This is different from initialize_session in that
    # it requires a running RPC server
    # @param message_handler [PuppetDebugServer::MessageRouter] The message router used to communicate with the Debug Client.
    # @param options [Hash<String, String>] Hash of launch arguments from the DSP launch request
    def setup(message_handler, options = {})
      @message_handler = message_handler
      @session_options = options
      flow_control.assert_flag(:session_setup)
    end

    # Synchronously runs Puppet in the debug session, assuming it has been configured correctly.
    # Requires the session_setup and client_completed_configuration flags to be set prior.
    def run_puppet
      # Perform pre-run checks...
      return if flow_control.terminate?
      raise 'Missing session setup' unless flow_control.flag?(:session_setup)
      raise 'Missing client configuration' unless flow_control.flag?(:client_completed_configuration)

      # Run puppet
      puppet_session_state.actual.reset!
      flow_control.assert_flag(:puppet_started)
      cmd_args = ['apply', @session_options['manifest'], '--detailed-exitcodes', '--logdest', 'debugserver']
      cmd_args << '--noop' if @session_options['noop'] == true
      cmd_args.push(*@session_options['args']) unless @session_options['args'].nil?

      # Send experimental warning
      send_output_event(
        'category' => 'console',
        'output'   => "**************************************************\n* The Puppet debugger is an experimental feature *\n* Debug Server v#{PuppetEditorServices.version}                           *\n**************************************************\n\n"
      )

      send_output_event(
        'category' => 'console',
        'output'   => 'puppet ' + cmd_args.join(' ') + "\n"
      )
      send_thread_event('started', @puppet_thread_id)

      Puppet::Util::CommandLine.new('puppet.rb', cmd_args).execute
    end

    # Creates the list of stack frames from the saved puppet session state
    # @see DSP::StackFrame
    # @return [Array<DSP::StackFrame>]
    def generate_stackframe_list
      stack_frames = []
      state = puppet_session_state.saved

      # Generate StackFrame for a Pops::Evaluator object with location information
      unless state.pops_target.nil?
        target = state.pops_target

        frame = DSP::StackFrame.new.from_h!(
          'id'     => stack_frames.count,
          'name'   => get_puppet_class_name(target),
          'line'   => 0,
          'column' => 0
        )

        # TODO: Need to check on the client capabilities of zero or one based indexes
        if target.is_a?(Puppet::Pops::Model::Positioned)
          target_loc = get_location_from_pops_object(target)
          frame.name   = target_loc.file
          frame.line   = target_loc.line
          frame.column = pos_on_line(target, target_loc.offset)
          frame.source = DSP::Source.new.from_h!('path' => target_loc.file)

          if target_loc.length > 0 # rubocop:disable Style/ZeroLengthPredicate
            end_offset = target_loc.offset + target_loc.length
            frame.endLine   = line_for_offset(target, end_offset)
            frame.endColumn = pos_on_line(target, end_offset)
          end
        end

        stack_frames << frame
      end

      # Generate StackFrame for an error
      unless state.exception.nil?
        err = state.exception
        frame = DSP::StackFrame.new.from_h!(
          'id'     => stack_frames.count,
          'name'   => err.class.to_s,
          'line'   => 0,
          'column' => 0
        )

        # TODO: Need to check on the client capabilities of zero or one based indexes
        unless err.file.nil? || err.line.nil?
          frame.source = DSP::Source.new.from_h!('path' => err.file)
          frame.line   = err.line
          frame.column = err.pos || 0
        end

        stack_frames << frame
      end

      # Generate StackFrame for each PuppetStack element
      unless state.puppet_stacktrace.nil?
        state.puppet_stacktrace.each do |pup_stack|
          source_file = pup_stack[0]
          # TODO: Need to check on the client capabilities of zero or one based indexes
          source_line = pup_stack[1]

          frame = DSP::StackFrame.new.from_h!(
            'id'     => stack_frames.count,
            'name'   => source_file.to_s,
            'source' => { 'path' => source_file },
            'line'   => source_line,
            'column' => 0
          )
          stack_frames << frame
        end
      end

      stack_frames
    end

    # Creates the list of scopes from the saved puppet session state
    # @see DSP::Scope
    # @return [Array<DSP::Scope>]
    def generate_scopes_list(frame_id)
      # Unfortunately we can only respond to Frame 0 as we don't have the variable state in other stack frames
      return [] unless frame_id.zero?

      result = []

      this_scope = puppet_session_state.saved.scope
      # rubocop:disable Lint/Void  Go home rubocop, you're drunk.
      until this_scope.nil? || this_scope.is_topscope?
        result << DSP::Scope.new.from_h!(
          'name'               => this_scope.to_s,
          'variablesReference' => this_scope.object_id,
          'namedVariables'     => this_scope.to_hash(false).count,
          'expensive'          => false
        )
        this_scope = this_scope.parent
      end
      # rubocop:enable Lint/Void

      unless puppet_session_state.actual.compiler.nil?
        result << DSP::Scope.new.from_h!(
          'name'               => puppet_session_state.actual.compiler.topscope.to_s,
          'variablesReference' => VARIABLES_REFERENCE_TOP_SCOPE,
          'namedVariables'     => puppet_session_state.actual.compiler.topscope.to_hash(false).count,
          'expensive'          => false
        )
      end
      result
    end

    # Creates the list of variables from the saved puppet session state, given the arguments from a DSP::VariablesArguments object
    # @see DSP::VariablesArguments
    # @see DSP::Variable
    # @return [Array<DSP::Variable>]
    def generate_variables_list(arguments)
      variables_reference = arguments.variablesReference
      result = nil

      # Check if this is the topscope
      if variables_reference == VARIABLES_REFERENCE_TOP_SCOPE # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
        result = variable_list_from_hash(puppet_session_state.actual.compiler.topscope.to_hash(false))
      end
      return result unless result.nil?

      # Could be a cached variables reference
      cache_list = puppet_session_state.saved.variable_cache[variables_reference]
      unless cache_list.nil?
        result = case cache_list
                 when Hash
                   variable_list_from_hash(cache_list)
                 when Array
                   variable_list_from_array(cache_list)
                 else
                   # Should never get here but just in case
                   []
                 end
      end
      return result unless result.nil?

      # Could be a child scope
      this_scope = puppet_session_state.saved.scope
      until this_scope.nil? || this_scope.is_topscope?
        if this_scope.object_id == variables_reference
          result = variable_list_from_hash(this_scope.to_hash(false))
          break
        end
        this_scope = this_scope.parent
      end
      return result unless result.nil?

      []
    end

    # Evaluates or "compiles" an arbitrary puppet language string in the current scope. This comes from a DSP::EvaluateRequest
    # which contains a DSP::EvaluateArguments object.
    # @see DSP::EvaluateRequest
    # @see DSP::EvaluateArguments
    # @param arguments [DSP::EvaluateArguments]
    # @returns [String, nil] Result of evaluating the string.
    def evaluate_string(arguments)
      raise "Unable to evaluate on Frame #{arguments.frameId}. Only the top-scope is supported" unless arguments.frameId.nil? || arguments.frameId.zero?
      return nil if arguments.expression.nil? || arguments.expression.to_s.empty?
      return nil if puppet_session_state.actual.compiler.nil?

      # Ignore any log messages when evaluating watch expressions. They just clutter the debug console for no reason.
      suppress_log = arguments.context == 'watch'

      @evaluating_parser ||= ::Puppet::Pops::Parser::EvaluatingParser.new

      # Unfortunately the log supression is global so we can only do one evaluation at a time.
      result = nil
      @evaluate_string_mutex.synchronize do
        if suppress_log
          flow_control.assert_flag(:suppress_log_messages) if suppress_log
          # Even though we're suppressing log messages, we still need to save them to emit errors in a different format
          message_aggregator = LogMessageAggregator.new(hook_manager)
          message_aggregator.start!
        end
        begin
          result = @evaluating_parser.evaluate_string(puppet_session_state.actual.compiler.topscope, arguments.expression)
          if result.nil? && suppress_log
            # A nil result could indicate a failure. Check the message_aggregator
            msgs = message_aggregator.messages.select { |log| ERROR_LOG_LEVELS.include?(log.level) }.map(&:message)
            raise msgs.join("\n") unless msgs.empty?
          end
        ensure
          if suppress_log
            flow_control.unassert_flag(:suppress_log_messages)
            message_aggregator.stop!
          end
        end
      end
      # As this will be transmitted over JSON, force the output to a string
      result.nil? ? nil : result.to_s
    end

    # Indicates that the debug session should stop gracefully
    def close
      send_termination_event
    end

    # Indicates that the debug session will be stopped in a forced manner
    def force_terminate
      @puppet_thread.exit unless @puppet_thread.nil?
    end

    # Retrieves the class name of a Puppet POPS object for Puppet 5+ and Puppet 4.x.
    #
    # @param obj [Object] The Puppet POPS object.
    # @return [String] Then class name of the object
    def get_puppet_class_name(obj)
      # Puppet 5+ has PCore Types
      return obj._pcore_type.simple_name if obj.respond_to?(:_pcore_type)
      # .. otherwise revert to simple naive text splitting
      # e.g. Puppet::Pops::Model::CallNamedFunctionExpression becomes CallNamedFunctionExpression
      obj.class.to_s.split('::').last
    end

    # Retrieves the location of Puppet POPS object within a manifest
    #
    # @param obj [Object] The Puppet POPS object.
    # @return [SourcePosition] The location of the object
    def get_location_from_pops_object(obj)
      # TODO: Should really use the SourceAdpater
      # https://github.com/puppetlabs/puppet-strings/blob/ede2b0e76c278c98d57aa80a550971e934ba93ef/lib/puppet-strings/yard/parsers/puppet/statement.rb#L22-L25
      pos = SourcePosition.new
      return pos unless obj.is_a?(Puppet::Pops::Model::Positioned)

      if obj.respond_to?(:file) && obj.respond_to?(:line)
        # These methods were added to the Puppet::Pops::Model::Positioned in Puppet 5.x
        pos.file   = obj.file
        pos.line   = obj.line
        pos.offset = obj.offset
        pos.length = obj.length
      else
        # Revert to Puppet 4.x location information.  A little more expensive to call
        obj_loc = Puppet::Pops::Utils.find_closest_positioned(obj)
        unless obj_loc.nil?
          pos.file   = obj_loc.locator.file
          pos.line   = obj_loc.line
          pos.offset = obj_loc.offset
          pos.length = obj_loc.length
        end
      end

      pos
    end

    # Retrieves the position on a line for a given document character offset
    #
    # @param obj [Object] The Puppet POPS object.
    # @param offset [Integer] The character offset in the manifest
    # @return [Integer] The position in the line
    def pos_on_line(obj, offset)
      # TODO: Should really use the SourceAdpater
      # https://github.com/puppetlabs/puppet-strings/blob/ede2b0e76c278c98d57aa80a550971e934ba93ef/lib/puppet-strings/yard/parsers/puppet/statement.rb#L22-L25

      # Puppet 5 exposes the source locator on the Pops object
      return obj.locator.pos_on_line(offset) if obj.respond_to?(:locator)

      # Revert to Puppet 4.x location information.  A little more expensive to call
      obj_loc = Puppet::Pops::Utils.find_closest_positioned(obj)
      obj_loc.locator.pos_on_line(offset)
    end

    # Retrieves line number for a given document character offset
    #
    # @param obj [Object] The Puppet POPS object.
    # @param offset [Integer] The line number
    # @return [Integer] The position in the line
    def line_for_offset(obj, offset)
      # TODO: Should really use the SourceAdpater
      # https://github.com/puppetlabs/puppet-strings/blob/ede2b0e76c278c98d57aa80a550971e934ba93ef/lib/puppet-strings/yard/parsers/puppet/statement.rb#L22-L25

      # Puppet 5 exposes the source locator on the Pops object
      return obj.locator.line_for_offset(offset) if obj.respond_to?(:locator)

      # Revert to Puppet 4.x location information.  A little more expensive to call
      obj_loc = Puppet::Pops::Utils.find_closest_positioned(obj)
      obj_loc.locator.line_for_offset(offset)
    end

    private

    # Converts a hash of ruby objects into an array of DSP::Variable objects
    #
    # @see DSP::Variable
    # @param obj_hash [Hash<Symbol, Object>] Hash of Puppet Objects
    # @return [Array<DSP::Variable>] Array of DSP::Variable
    # @private
    def variable_list_from_hash(obj_hash = {})
      result = []
      obj_hash.sort.each do |key, value|
        result << variable_from_ruby_object(key, value)
      end

      result
    end

    # Converts an array of ruby objects into an array of DSP::Variable objects
    #
    # @see DSP::Variable
    # @param obj_hash [Array<Object>] Array of Puppet Objects
    # @return [Array<DSP::Variable>] Array of DSP::Variable
    # @private
    def variable_list_from_array(obj_array = [])
      result = []
      # TODO: Could use obj_array.map.each_with_index ... ?
      obj_array.each_index do |index|
        result << variable_from_ruby_object(index.to_s, obj_array[index])
      end
      result
    end

    # Converts a ruby object into a DSP::Variable object
    #
    # @see DSP::Variable
    # @param name [String] The name of the variable
    # @param value [Object] The value of the variable
    # @return [DSP::Variable]
    # @private
    def variable_from_ruby_object(name, value)
      var_ref = 0
      out_value = value.to_s

      if value.is_a?(Array)
        indexed_variables = value.count
        var_ref = value.object_id
        out_value = "Array [#{indexed_variables} item/s]"
        puppet_session_state.saved.variable_cache[var_ref] = value
      end

      if value.is_a?(Hash)
        named_variables = value.count
        var_ref = value.object_id
        out_value = "Hash [#{named_variables} item/s]"
        puppet_session_state.saved.variable_cache[var_ref] = value
      end

      DSP::Variable.new.from_h!(
        'name'               => name,
        'value'              => out_value,
        'variablesReference' => var_ref
      )
    end
  end

  # A simple class which represents the position of somethin within a source document
  class SourcePosition
    # The path of the source file
    # @return [String]
    attr_accessor :file

    # The line in the source file
    # @return [Integer]
    attr_accessor :line

    # The absolute offset of the location in the source file
    # @return [Integer]
    attr_accessor :offset

    # The numner of characters this position encompasses
    # @return [Integer]
    attr_accessor :length
  end

  # A helper class which hooks into log messages and saves them in receive order
  class LogMessageAggregator
    # The saved messages
    # @return [Array<Puppet::Util::Log>]
    attr_reader :messages

    # @param hook_manager [PuppetDebugServer::Hooks] The hook manager to use
    def initialize(hook_manager)
      @hook_manager = hook_manager
      @hook_id = "aggregator#{object_id}".intern
      @messages = []
      @started = false
    end

    # Start aggregating log messages
    def start!
      return if @started
      @hook_manager.add_hook(:hook_log_message, @hook_id) { |args| on_hook_log_message(args) }
    end

    # Stop aggregating log messages
    def stop!
      return unless @started
      @hook_manager.delete_hook(:hook_log_message, @hook_id)
    end

    # Fires when a message is sent to the puppet logger
    # Arguments:
    #   Message - The message being sent to the log
    def on_hook_log_message(args)
      @messages << args[0]
    end
  end
end

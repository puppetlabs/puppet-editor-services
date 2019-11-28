# frozen_string_literal: true

module PuppetDebugServer
  module DebugSession
    # Implements the hooks within the debug session.
    #
    # @todo The following hooks are not implemented
    # :hook_after_compile
    #   Fires after a catalog compilation is succesfully completed
    #   Arguments:
    #     Puppet::Resource::Catalog - Resultant compiled catalog
    #
    # :hook_before_parser_function_reset
    #   Fires before the Puppet::Parser::Functions is reset, destroying the existing list of loaded functions
    #   Arguments:
    #     Puppet::Parser::Functions - Instance of Puppet::Parser::Functions
    #
    class HookHandlers
      # List of Puppet POPS classes that the Source Breakpoints will NOT trigger on
      EXCLUDED_CLASSES = %w[BlockExpression HostClassDefinition].freeze

      # @param debug_session [PuppetDebugServer::PuppetDebugSession] The debug session to manage the hooks for.
      def initialize(debug_session)
        @debug_session = debug_session

        @debug_session.hook_manager.add_hook(:hook_after_parser_function_reset, :debug_session) { |args| on_hook_after_parser_function_reset(args) }
        @debug_session.hook_manager.add_hook(:hook_after_pops_evaluate, :debug_session)         { |args| on_hook_after_pops_evaluate(args) }
        @debug_session.hook_manager.add_hook(:hook_before_apply_exit, :debug_session)           { |args| on_hook_before_apply_exit(args) }
        @debug_session.hook_manager.add_hook(:hook_before_compile, :debug_session)              { |args| on_hook_before_compile(args) }
        @debug_session.hook_manager.add_hook(:hook_before_pops_evaluate, :debug_session)        { |args| on_hook_before_pops_evaluate(args) }
        @debug_session.hook_manager.add_hook(:hook_breakpoint, :debug_session)                  { |args| on_hook_breakpoint(args) }
        @debug_session.hook_manager.add_hook(:hook_exception, :debug_session)                   { |args| on_hook_exception(args) }
        @debug_session.hook_manager.add_hook(:hook_function_breakpoint, :debug_session)         { |args| on_hook_function_breakpoint(args) }
        @debug_session.hook_manager.add_hook(:hook_log_message, :debug_session)                 { |args| on_hook_log_message(args) }
        @debug_session.hook_manager.add_hook(:hook_step_breakpoint, :debug_session)             { |args| on_hook_step_breakpoint(args) }
      end

      #  Fires after the Puppet::Parser::Functions class is reset
      #  Arguments:
      #    Puppet::Parser::Functions - Instance of Puppet::Parser::Functions
      def on_hook_after_parser_function_reset(args)
        func_object = args[0]

        # This mimics the break function from puppet-debugger
        # https://github.com/nwops/puppet-debug#usage
        func_object.newfunction(:'debug::break', :type => :rvalue, :arity => -1, :doc => 'Breakpoint Function') do |arguments|
          # This function is just a place holder. It gets interpretted at the
          # pops_evaluate hooks but the function itself still needs to exist though.
        end
      end

      # Fires after an item in the AST is evaluated
      # Arguments:
      #   The Pops object about to be evaluated
      #   The scope of the Pops object
      def on_hook_after_pops_evaluate(_args)
        # If the debug session is paused no need to process
        return if @debug_session.flow_control.session_paused?

        @debug_session.puppet_session_state.actual.decrement_pops_depth
      end

      # Fires before the Puppet::Apply application tries to call Kernel#exit.
      # Arguments:
      #   Integer - Exit Code
      def on_hook_before_apply_exit(args)
        option = args[0]

        @debug_session.send_exited_event(option)
        @debug_session.send_output_event(
          'category' => 'console',
          'output'   => "puppet exited with #{option}"
        )

        @debug_session.flow_control.unassert_flag(:puppet_started)
        @debug_session.close

        # Wait up to 30 seconds for the client to disconnect and stop the debug session
        # Anymore than that and we force the debug session to stop.
        sleep(30)
        @debug_session.force_terminate
      end

      # Fires before a catalog compilation is attempted
      # Arguments:
      #   Puppet::Parser::Compiler - Current compiler in use
      def on_hook_before_compile(args)
        @debug_session.puppet_session_state.actual.update_compiler(args[0])

        # Spin-wait for the configurationDone message from the client before we continue compilation
        return if @debug_session.flow_control.flag?(:client_completed_configuration)
        sleep(0.5) until @debug_session.flow_control.flag?(:client_completed_configuration)
      end

      #   Fires before an item in the AST is evaluated during a catalog compilation
      #   Arguments:
      #     The Pops object about to be evaluated
      #     The scope of the Pops object
      def on_hook_before_pops_evaluate(args)
        # If the debug session is paused no need to process
        return if @debug_session.flow_control.session_paused?

        @debug_session.puppet_session_state.actual.increment_pops_depth

        target = args[1]
        # Ignore this if there is no positioning information available
        return unless target.is_a?(Puppet::Pops::Model::Positioned)
        target_loc = @debug_session.get_location_from_pops_object(target)

        # Even if it's positioned, it can still contain invalid information.  Ignore it if
        # it's missing required information.  This can happen when evaluting strings (e.g. watches from VSCode)
        # i.e. not a file on disk
        return if target_loc.file.nil? || target_loc.file.empty?
        target_classname = @debug_session.get_puppet_class_name(target)
        ast_classname = get_ast_class_name(target)

        # Break if we hit a specific puppet function
        if target_classname == 'CallNamedFunctionExpression' && @debug_session.breakpoints.function_breakpoint_names.include?(target.functor_expr.value)
          # Re-raise the hook as a breakpoint
          @debug_session.execute_hook(:hook_function_breakpoint, [target.functor_expr.value, ast_classname] + args)
          return
        end

        # Check for Source based breakpoints
        unless target_loc.length.zero? || EXCLUDED_CLASSES.include?(target_classname)
          line_breakpoints = @debug_session.breakpoints.line_breakpoints(target_loc.file)

          # Calculate the start and end lines of the target
          target_start_line = target_loc.line
          target_end_line   = @debug_session.line_for_offset(target, target_loc.offset + target_loc.length)

          # TODO: What about Hit and Conditional BreakPoints?
          bp = line_breakpoints.find_index { |bp_line| bp_line >= target_start_line && bp_line <= target_end_line }
          unless bp.nil?
            # Re-raise the hook as a breakpoint
            @debug_session.execute_hook(:hook_breakpoint, [ast_classname, ''] + args)
            return
          end
        end

        # Break if we are stepping
        case @debug_session.flow_control.run_mode.mode
        when :stepin
          # Stepping-in is basically break on everything
          # Re-raise the hook as a step breakpoint
          @debug_session.execute_hook(:hook_step_breakpoint, [ast_classname, ''] + args)
        when :next
          # Next will break on anything at this Pop depth or shallower than this Pop depth. Re-raise the hook as a step breakpoint
          depth = @debug_session.flow_control.run_mode.options[:pops_depth_level] || -1
          if @debug_session.puppet_session_state.actual.pops_depth_level <= depth # rubocop:disable Style/IfUnlessModifier
            @debug_session.execute_hook(:hook_step_breakpoint, [ast_classname, ''] + args)
          end
        when :stepout
          # Stepping-Out will break on anything shallower than this Pop depth. Re-raise the hook as a step breakpoint
          depth = @debug_session.flow_control.run_mode.options[:pops_depth_level] || -1
          if @debug_session.puppet_session_state.actual.pops_depth_level < depth # rubocop:disable Style/IfUnlessModifier
            @debug_session.execute_hook(:hook_step_breakpoint, [ast_classname, ''] + args)
          end
        end
        nil
      end

      # Fires when a source/line breakpoint is hit
      # Arguments:
      #   String - Breakpoint display text
      #   String - Breakpoint full text
      #   Object - self where the breakpoint was hit
      #   Object[] - optional objects
      def on_hook_breakpoint(args)
        process_breakpoint_hook('breakpoint', args)
      end

      # Fires when an unhandled exception is hit during puppet apply
      # Arguments:
      #   Error - The exception information
      def on_hook_exception(args)
        # If the debug session is paused, can't raise a new exception
        return if @debug_session.flow_control.session_paused?

        error_detail = args[0]

        @debug_session.flow_control.raise_stopped_event_and_wait(
          'exception',
          'Compilation Exception',
          error_detail.basic_message,
          :session_exception => error_detail,
          :puppet_stacktrace => Puppet::Pops::PuppetStack.stacktrace_from_backtrace(error_detail)
        )
      end

      # Fires when a function breakpoint is hit
      # Arguments:
      #   String - Breakpoint display text
      #   String - Breakpoint full text
      #   Object - self where the function breakpoint was hit
      #   Object[] - optional objects
      def on_hook_function_breakpoint(args)
        process_breakpoint_hook('function breakpoint', args)
      end

      # Fires when a message is sent to the puppet logger
      # Arguments:
      #   Message - The message being sent to the log
      def on_hook_log_message(args)
        return if @debug_session.flow_control.flag?(:suppress_log_messages)

        msg = args[0]
        str = msg.respond_to?(:multiline) ? msg.multiline : msg.to_s
        str = msg.source == 'Puppet' ? str : "#{msg.source}: #{str}"

        level = msg.level.to_s.capitalize

        category = 'stderr'
        category = 'stdout' if msg.level == :notice || msg.level == :info || msg.level == :debug

        @debug_session.send_output_event(
          'category' => category,
          'output'   => "#{level}: #{str}\n"
        )
      end

      # Fires when a function breakpoint is hit
      # Arguments:
      #   String - Breakpoint display text
      #   String - Breakpoint full text
      #   Object - self where the step breakpoint was hit
      #   Object[] - optional objects
      def on_hook_step_breakpoint(args)
        process_breakpoint_hook('step', args)
      end

      private

      # Raises a stop event and waits for the debug session to continue for a given breakpoint type.
      #
      # @param reason [String] The type of breakpoint that was hit
      # @param args [Array<Object>] An array of arguments for the breakpoint
      # @private
      def process_breakpoint_hook(reason, args)
        # If the debug session is paused no need to process
        return if @debug_session.flow_control.session_paused?
        break_display_text = args[0] # TODO: REALLY don't like all this magic array stuff. Real Object? Hash?
        break_description = args[1]

        scope_object = nil
        pops_target_object = nil
        pops_depth_level = nil

        # Check if the breakpoint came from the Pops::Evaluator
        if args[2].is_a?(Puppet::Pops::Evaluator::EvaluatorImpl)
          pops_target_object = args[3]
          scope_object = args[4]
          pops_depth_level = @debug_session.puppet_session_state.actual.pops_depth_level
        end

        break_description = break_display_text if break_description.empty?
        # Due to a modification to the way stack traces are treated in Puppet 6.11.0, the stack
        # now includes entries for files in Line 0, which doesn't exist. These indicate that a file
        # has started to be processed/parsed/compiled. So we just ignore them
        # See https://tickets.puppetlabs.com/browse/PUP-10150 for more infomation
        stack_trace = Puppet::Pops::PuppetStack.stacktrace.reject { |item| item[1].zero? }
        # Due to https://github.com/puppetlabs/puppet/commit/0f96dd918b6184261bc2219e5e68e246ffbeac10
        # Prior to Puppet 4.8.0, stacktrace is in reverse order
        stack_trace.reverse! if Gem::Version.new(Puppet.version) < Gem::Version.new('4.8.0')

        @debug_session.flow_control.raise_stopped_event_and_wait(
          reason,
          break_display_text,
          break_description,
          :pops_target       => pops_target_object,
          :scope             => scope_object,
          :pops_depth_level  => pops_depth_level,
          :puppet_stacktrace => stack_trace
        )
      end

      # Retrieves the name of a Puppet AST object for Puppet 5+ and Puppet 4.x.
      #
      # @param obj [Object] The Puppet POPS object.
      # @return [String] Then class name of the object
      # @private
      def get_ast_class_name(obj)
        # Puppet 5 has PCore Types
        return obj._pcore_type.name if obj.respond_to?(:_pcore_type)
        # .. otherwise revert to Pops classname
        obj.class.to_s
      end
    end
  end
end

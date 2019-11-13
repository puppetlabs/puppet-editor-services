# frozen_string_literal: true

require 'puppet_editor_services/handler/debug_adapter'

module PuppetDebugServer
  class MessageHandler < PuppetEditorServices::Handler::DebugAdapter
    def initialize(*_options)
      super
    end

    # region Message Helpers
    def send_exited_event(exitcode)
      protocol.encode_and_send(
        PuppetEditorServices::Protocol::DebugAdapterMessages.new_event(
          'exited',
          'exitCode' => exitcode
        )
      )
    end

    def send_output_event(body_content)
      protocol.encode_and_send(PuppetEditorServices::Protocol::DebugAdapterMessages.new_event('output', body_content))
    end

    def send_stopped_event(reason, options = {})
      protocol.encode_and_send(
        PuppetEditorServices::Protocol::DebugAdapterMessages.new_event(
          'stopped',
          { 'reason' => reason }.merge(options)
        )
      )
    end

    def send_termination_event
      protocol.encode_and_send(PuppetEditorServices::Protocol::DebugAdapterMessages.new_event('terminated'))
    end

    def send_thread_event(reason, thread_id)
      protocol.encode_and_send(
        PuppetEditorServices::Protocol::DebugAdapterMessages.new_event(
          'thread',
          'reason' => reason, 'threadId' => thread_id
        )
      )
    end
    # end region

    def request_configurationdone(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received configurationDone request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance

      debug_session.flow_control.assert_flag(:client_completed_configuration)

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message)
    end

    def request_continue(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received continue request.')

      # Continue the debug session
      PuppetDebugServer::PuppetDebugSession.instance.flow_control.continue!

      # Send response. We only actually have one thread, but simulate the
      # allThreadsContinued setting
      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'allThreadsContinued' => true
      )
    end

    def request_disconnect(_connection_id, _request_message)
      # Don't really care about the arguments - Kill everything
      PuppetDebugServer.log_message(:info, 'Received disconnect request.  Closing connection to client...')
      protocol.close_connection
    end

    def request_evaluate(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received evaluate request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) unless debug_session.flow_control.session_active?
      obj = DSP::EvaluateRequest.new(request_message.to_h)
      begin
        PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
          request_message,
          'result' => debug_session.evaluate_string(obj.arguments), 'variablesReference' => 0
        )
      rescue => e # rubocop:disable Style/RescueStandardError  Anything could be thrown here. Catch 'em all
        PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(
          request_message,
          e.to_s
        )
      end
    end

    def request_initialize(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received initialize request.')
      # Save the client capabilities for later use
      @client_capabilities = request_message.arguments.to_h

      # Send capability response
      capabilities = DSP::Capabilities.new
      # We can't accept breakpoints at any time so need them upfront
      capabilities.supportsConfigurationDoneRequest  = true
      # The different kind of breakpoints the server supports
      capabilities.supportsFunctionBreakpoints       = true
      capabilities.supportsConditionalBreakpoints    = false
      capabilities.supportsHitConditionalBreakpoints = false
      capabilities.supportsDataBreakpoints           = false
      capabilities.supportsLogPoints                 = false
      capabilities.supportsExceptionOptions          = false
      # We don't have any filters
      capabilities.exceptionBreakpointFilters        = []
      # We only have one thread so no need for this
      capabilities.supportsTerminateThreadsRequest   = false
      capabilities.supportTerminateDebuggee          = false
      # But we can terminate
      capabilities.supportsTerminateRequest          = true
      # We can't really restart or go backwards
      capabilities.supportsRestartRequest            = false
      capabilities.supportsStepBack                  = false
      capabilities.supportsRestartFrame              = false
      # While Puppet "variables" are immutable (and poorly named) when can create new ones
      capabilities.supportsSetVariable               = true
      capabilities.supportsSetExpression             = false
      # We don't support Targets
      capabilities.supportsGotoTargetsRequest        = false
      capabilities.supportsStepInTargetsRequest      = false
      # Puppet doesn't have those kind of modules
      capabilities.supportsModulesRequest            = false
      # We don't have that kinda memory or disassembly
      capabilities.supportsReadMemoryRequest         = false
      capabilities.supportsDisassembleRequest        = false
      # Other capabilites which don't make sens in a Puppet world, yet.
      capabilities.supportsEvaluateForHovers         = false
      capabilities.supportsCompletionsRequest        = false
      capabilities.additionalModuleColumns           = []
      capabilities.supportedChecksumAlgorithms       = []
      capabilities.supportsValueFormattingOptions    = false
      capabilities.supportsExceptionInfoRequest      = false
      capabilities.supportsDelayedStackTraceLoading  = false
      capabilities.supportsLoadedSourcesRequest      = false

      # Do some initialization
      # .... dum de dum ...
      protocol.encode_and_send(PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message, capabilities))

      # Send a message that we are initialized
      # This must happen _after_ the capabilites are sent. This is pretty janky but _meh_
      sleep(0.5) # Sleep for a small amount of time to give the client time to process the capabilites response
      PuppetEditorServices::Protocol::DebugAdapterMessages.new_event('initialized')
    end

    def request_launch(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received launch request.')
      # TODO: Do we care about the noDebug?

      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      # Setup the debug session
      # Can't use the DSP::LaunchRequest object here because the arguments are dynamic
      # The :session_setup flag is asserted inside the setup method so no need to for us to do that here
      debug_session.setup(self, request_message.arguments)

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message)
    end

    def request_next(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received next request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      obj = DSP::NextRequest.new(request_message.to_h)
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
      # Stepout the debug session
      debug_session.flow_control.next!
      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message)
    end

    def request_scopes(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received scopes request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) unless debug_session.flow_control.session_active?
      obj = DSP::ScopesRequest.new(request_message.to_h)

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'scopes' => debug_session.generate_scopes_list(obj.arguments.frameId)
      )
    end

    def request_setbreakpoints(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received setBreakpoints request.')
      req = DSP::SetBreakpointsRequest.new(request_message.to_h)
      debug_session = PuppetDebugServer::PuppetDebugSession.instance

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'breakpoints' => debug_session.breakpoints.process_set_breakpoints_request!(req.arguments)
      )
    end

    def request_setfunctionbreakpoints(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received setFunctionBreakpoints request.')
      req = DSP::SetFunctionBreakpointsRequest.new(request_message.to_h)
      debug_session = PuppetDebugServer::PuppetDebugSession.instance

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'breakpoints' => debug_session.breakpoints.process_set_function_breakpoints_request!(req.arguments)
      )
    end

    def request_stacktrace(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received stackTrace request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      obj = DSP::StackTraceRequest.new(request_message.to_h)
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId

      frames = debug_session.generate_stackframe_list

      # TODO: Should really trim the frame information for the given stack trace request
      #         /** The index of the first frame to return; if omitted frames start at 0. */
      #         startFrame?: number;
      #         /** The maximum number of frames to return. If levels is not specified or 0, all frames are returned. */
      #         levels?: number;
      #         /** Specifies details on how to format the stack frames. */
      #         format?: StackFrameFormat;
      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'stackFrames' => frames, 'totalFrames' => frames.count
      )
    end

    def request_stepin(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received stepIn request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      obj = DSP::StepInRequest.new(request_message.to_h)
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
      # Stepin the debug session
      debug_session.flow_control.step_in!
      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message)
    end

    def request_stepout(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received stepOut request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      obj = DSP::StepOutRequest.new(request_message.to_h)
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
      # Stepout the debug session
      debug_session.flow_control.step_out!
      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(request_message)
    end

    def request_threads(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received threads request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) if debug_session.puppet_thread_id.nil?

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        # There is only one thread
        'threads' => [{ 'id' => debug_session.puppet_thread_id, 'name' => 'puppet' }]
      )
    end

    def request_variables(_connection_id, request_message)
      PuppetDebugServer.log_message(:debug, 'Received variables request.')
      debug_session = PuppetDebugServer::PuppetDebugSession.instance
      return PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message) unless debug_session.flow_control.session_active?
      obj = DSP::VariablesRequest.new(request_message.to_h)

      PuppetEditorServices::Protocol::DebugAdapterMessages.reply_success(
        request_message,
        'variables' => debug_session.generate_variables_list(obj.arguments)
      )
    end
  end
end

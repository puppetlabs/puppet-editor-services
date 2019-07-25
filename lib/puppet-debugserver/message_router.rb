# frozen_string_literal: true

module PuppetDebugServer
  class MessageRouter
    attr_accessor :json_handler

    def initialize(*_options)
    end

    def create_response_from_request(response_class, request, hash = { 'success' => true })
      obj = response_class.new.from_h!(hash)

      obj.type        = 'response'
      obj.request_seq = request.seq
      obj.command     = request.command
      obj
    end

    def send_exited_event(exitcode)
      obj = DSP::ExitedEvent.new.from_h!(
        'type'  => 'event',
        'event' => 'exited',
        'body'  => {
          'exitCode' => exitcode
        }
      )
      @json_handler.send_event obj
    end

    def send_output_event(options)
      obj = DSP::OutputEvent.new.from_h!(
        'type'  => 'event',
        'event' => 'output',
        'body'  => options
      )
      @json_handler.send_event obj
    end

    def send_stopped_event(reason, options = {})
      obj = DSP::StoppedEvent.new.from_h!(
        'type'  => 'event',
        'event' => 'stopped',
        'body'  => { 'reason' => reason }.merge(options)
      )
      @json_handler.send_event obj
    end

    def send_termination_event
      obj = DSP::TerminatedEvent.new.from_h!(
        'type'  => 'event',
        'event' => 'terminated'
      )
      @json_handler.send_event obj
    end

    def send_thread_event(reason, thread_id)
      obj = DSP::ThreadEvent.new.from_h!(
        'type'  => 'event',
        'event' => 'thread',
        'body'  => {
          'reason'   => reason,
          'threadId' => thread_id
        }
      )
      @json_handler.send_event obj
    end

    def receive_request(request, original_request)
      case request.command
      when 'configurationDone'
        PuppetDebugServer.log_message(:debug, 'Received configurationDone request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance

        debug_session.flow_control.assert_flag(:client_completed_configuration)

        response = create_response_from_request(DSP::ConfigurationDoneResponse, request)
        @json_handler.send_response response

      when 'continue'
        PuppetDebugServer.log_message(:debug, 'Received continue request.')

        # Continue the debug session
        PuppetDebugServer::PuppetDebugSession.instance.flow_control.continue!

        # Send response. We only actually have one thread, but simulate the
        # allThreadsContinued setting
        response = create_response_from_request(
          DSP::ContinueResponse,
          request,
          'success' => true,
          'body'    => {
            'allThreadsContinued' => true
          }
        )
        @json_handler.send_response response

      when 'disconnect'
        # Don't really care about the arguments - Kill everything
        PuppetDebugServer.log_message(:info, 'Received disconnect request.  Closing connection to client...')
        @json_handler.close_connection

      when 'evaluate'
        PuppetDebugServer.log_message(:debug, 'Received evaluate request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        unless debug_session.flow_control.session_active?
          response = create_response_from_request(DSP::Response, request, 'success' => false)
          @json_handler.send_response response
          return
        end
        obj = DSP::EvaluateRequest.new.from_h!(original_request)

        begin
          response = create_response_from_request(
            DSP::EvaluateResponse,
            request,
            'success' => true,
            'body'    => {
              'result'             => debug_session.evaluate_string(obj.arguments),
              'variablesReference' => 0
            }
          )
          @json_handler.send_response response
        rescue => e # rubocop:disable Style/RescueStandardError  Anything could be thrown here. Catch 'em all
          response = create_response_from_request(DSP::Response, request, 'success' => false, 'message' => e.to_s)
          @json_handler.send_response response
        end

      when 'initialize'
        PuppetDebugServer.log_message(:debug, 'Received initialize request.')

        req = DSP::InitializeRequest.new.from_h!(original_request)
        # Save the client capabilities for later use
        @client_capabilities = req.arguments.to_h

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

        response = create_response_from_request(DSP::InitializeResponse, request)
        response.body = capabilities
        @json_handler.send_response response

        # Send a message that we are initialized
        # This must happen _after_ the capabilites are sent
        sleep(0.5) # Sleep for a small amount of time to give the client time to process the capabilites response
        @json_handler.send_event DSP::InitializedEvent.new.from_h!('type' => 'event', 'event' => 'initialized')

      when 'launch'
        PuppetDebugServer.log_message(:debug, 'Received launch request.')
        # TODO: Do we care about the noDebug?

        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        # Setup the debug session
        # Can't use the DSP::LaunchRequest object here because the arguments are dynamic
        # The :session_setup flag is asserted inside the setup method so need to for us to do it
        debug_session.setup(self, request.arguments)

        response = create_response_from_request(DSP::LaunchResponse, request)
        @json_handler.send_response response

      when 'scopes'
        PuppetDebugServer.log_message(:debug, 'Received scopes request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        unless debug_session.flow_control.session_active?
          response = create_response_from_request(DSP::Response, request, 'success' => false)
          @json_handler.send_response response
          return
        end
        obj = DSP::ScopesRequest.new.from_h!(original_request)

        response = create_response_from_request(
          DSP::ScopesResponse,
          request,
          'success' => true,
          'body'    => {
            'scopes' => debug_session.generate_scopes_list(obj.arguments.frameId)
          }
        )
        @json_handler.send_response response

      when 'next'
        PuppetDebugServer.log_message(:debug, 'Received next request.')

        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        obj = DSP::NextRequest.new.from_h!(original_request)
        if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
          @json_handler.send_response create_response_from_request(DSP::Response, request, 'success' => false)
          return
        end
        # Stepout the debug session
        debug_session.flow_control.next!
        @json_handler.send_response create_response_from_request(DSP::NextResponse, request, 'success' => true)

      when 'setBreakpoints'
        PuppetDebugServer.log_message(:debug, 'Received setBreakpoints request.')
        req = DSP::SetBreakpointsRequest.new.from_h!(original_request)
        debug_session = PuppetDebugServer::PuppetDebugSession.instance

        response = create_response_from_request(
          DSP::SetBreakpointsResponse,
          request,
          'success' => true,
          'body'    => {
            'breakpoints' => debug_session.breakpoints.process_set_breakpoints_request!(req.arguments)
          }
        )
        @json_handler.send_response response

      when 'setFunctionBreakpoints'
        PuppetDebugServer.log_message(:debug, 'Received setFunctionBreakpoints request.')
        req = DSP::SetFunctionBreakpointsRequest.new.from_h!(original_request)
        debug_session = PuppetDebugServer::PuppetDebugSession.instance

        response = create_response_from_request(
          DSP::SetFunctionBreakpointsResponse,
          request,
          'success' => true,
          'body'    => {
            'breakpoints' => debug_session.breakpoints.process_set_function_breakpoints_request!(req.arguments)
          }
        )
        @json_handler.send_response response

      when 'stackTrace'
        PuppetDebugServer.log_message(:debug, 'Received stackTrace request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        obj = DSP::StackTraceRequest.new.from_h!(original_request)
        if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
          response = create_response_from_request(DSP::Response, request, 'success' => false)
          @json_handler.send_response response
          return
        end

        frames = debug_session.generate_stackframe_list

        # TODO: Should really trim the frame information for the given stack trace request
        #         /** The index of the first frame to return; if omitted frames start at 0. */
        #         startFrame?: number;
        #         /** The maximum number of frames to return. If levels is not specified or 0, all frames are returned. */
        #         levels?: number;
        #         /** Specifies details on how to format the stack frames. */
        #         format?: StackFrameFormat;
        response = create_response_from_request(
          DSP::StackTraceResponse,
          request,
          'success' => true,
          'body'    => {
            'stackFrames' => frames,
            'totalFrames' => frames.count
          }
        )
        @json_handler.send_response response

      when 'stepIn'
        PuppetDebugServer.log_message(:debug, 'Received stepIn request.')

        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        obj = DSP::StepInRequest.new.from_h!(original_request)
        if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
          @json_handler.send_response create_response_from_request(DSP::Response, request, 'success' => false)
          return
        end
        # Stepin the debug session
        debug_session.flow_control.step_in!
        @json_handler.send_response create_response_from_request(DSP::StepInResponse, request, 'success' => true)

      when 'stepOut'
        PuppetDebugServer.log_message(:debug, 'Received stepOut request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        obj = DSP::StepOutRequest.new.from_h!(original_request)
        if debug_session.puppet_thread_id.nil? || debug_session.puppet_thread_id != obj.arguments.threadId
          @json_handler.send_response create_response_from_request(DSP::Response, request, 'success' => false)
          return
        end
        # Stepout the debug session
        debug_session.flow_control.step_out!
        @json_handler.send_response create_response_from_request(DSP::StepInResponse, request, 'success' => true)

      when 'threads'
        PuppetDebugServer.log_message(:debug, 'Received threads request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        if debug_session.puppet_thread_id.nil?
          @json_handler.send_response create_response_from_request(DSP::Response, request, 'success' => false)
          return
        end
        # Stepout the debug session
        @json_handler.send_response create_response_from_request(
          DSP::ThreadsResponse,
          request,
          'success' => true,
          'body'    => {
            # There is only one thread
            'threads' => [{ 'id' => debug_session.puppet_thread_id, 'name' => 'puppet' }]
          }
        )

      when 'variables'
        PuppetDebugServer.log_message(:debug, 'Received variables request.')
        debug_session = PuppetDebugServer::PuppetDebugSession.instance
        unless debug_session.flow_control.session_active?
          response = create_response_from_request(DSP::Response, request, 'success' => false)
          @json_handler.send_response response
          return
        end
        obj = DSP::VariablesRequest.new.from_h!(original_request)

        response = create_response_from_request(
          DSP::VariablesResponse,
          request,
          'success' => true,
          'body'    => {
            'variables' => debug_session.generate_variables_list(obj.arguments)
          }
        )
        @json_handler.send_response response

      else
        PuppetDebugServer.log_message(:error, "Unknown request command #{request.command}")

        response = create_response_from_request(DSP::Response, request, 'success' => false, 'message' => "This feature is not supported - Request #{request.command}")
        @json_handler.send_response response
      end
    end
  end
end

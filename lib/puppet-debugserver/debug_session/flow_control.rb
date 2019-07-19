# frozen_string_literal: true

module PuppetDebugServer
  module DebugSession
    # Manages the flags used to control the flow of puppet and Debugger during a debug session.
    class FlowControl
      # What mode the debug session is running in
      # @see PuppetDebugServer::DebugSession::PuppetSessionRunMode
      # @return [PuppetDebugServer::DebugSession::PuppetSessionRunMode]
      attr_reader :run_mode

      # @param debug_session [PuppetDebugServer::PuppetDebugSession] The debug session to manage the flow for.
      def initialize(debug_session)
        @debug_session = debug_session

        @flag_mutex = Mutex.new
        @flags = {
          :start_puppet                   => false,
          :puppet_started                 => false,
          :session_paused                 => false,
          :client_completed_configuration => false,
          :session_setup                  => false,
          :terminate                      => false,
          :suppress_log_messages          => false
        }

        @run_mode = PuppetDebugServer::DebugSession::PuppetSessionRunMode.new
      end

      # Returns which flags are set.
      #
      # Available flags
      # :start_puppet                       Indicates the main thread can start running Puppet and begin the debug session
      # :puppet_started                     Indicates the main thread has started running puppet and debug session is now active
      # :session_paused                     Indicates that the debug session has hit a breakpoint and is currently paused
      # :client_completed_configuration     The debug client has completed it's configuration
      # :session_setup                      This debug session has been setup ready to start
      # :terminate                          Indicates that all threads and wait processes should terminate
      # :suppress_log_messages              Indicates that Puppet log messages should not be sent to the client
      #
      # @param flag_name [Symbol] The name of the flag
      # @return [Boolean] Whether the flag is set
      def flag?(flag_name)
        result = false
        @flag_mutex.synchronize do
          result = @flags[flag_name]
        end
        result.nil? ? false : result
      end

      # Asserts a flag is set
      #
      # @param flag_name [Symbol] The name of the flag
      def assert_flag(flag_name)
        @flag_mutex.synchronize do
          @flags[flag_name] = true
          PuppetDebugServer.log_message(:debug, "Asserting flag #{flag_name} is true")
          # Any custom logic for when flags are asserted
          if flag_name == :client_completed_configuration || flag_name == :session_setup # rubocop:disable Style/MultipleComparison  This is faster and doesn't require creation of an array
            # If the client_completed_configuration and session_setup flag are asserted but the session isn't active yet
            # assert the flag start_puppet so puppet can start in the main thread.
            if !@flags[:puppet_started] && @flags[:client_completed_configuration] && @flags[:session_setup]
              PuppetDebugServer.log_message(:debug, 'Asserting flag start_puppet is true')
              @flags[:start_puppet] = true
            end
          end
          @terminate_flag = true if flag_name == :terminate
        end
      end

      # Removes/unasserts a flag
      #
      # @param flag_name [Symbol] The name of the flag
      def unassert_flag(flag_name)
        return if flag_name == :terminate # Can never unset the terminate flag
        @flag_mutex.synchronize do
          @flags[flag_name] = false
          PuppetDebugServer.log_message(:debug, "Unasserting flag #{flag_name} is true")
        end
      end

      # The terminate flag will be queried quite often during spin-wait cycles and it's basically immutable (i.e. Once set it can not be unset).
      # So to help speed up access just treat it as a normal boolean. This can also stop any deadlocks.
      #
      # @return [Boolean] Whether the debug session should be terminating.
      def terminate?
        @terminate_flag
      end

      # Whether the debug session has started.
      #
      # @return [Boolean] Returns true if the debug session has started.
      def session_active?
        flag?(:puppet_started)
      end

      # Whether the debug session is paused due to breakpoints.
      #
      # @return [Boolean] Returns true if the debug session is paused.
      def session_paused?
        flag?(:session_paused)
      end

      # Raises a stopped event to the Debug Client and waits for the debug session to continue.
      #
      # @param reason [String] The reason for the event. Values: 'step', 'breakpoint', 'exception', 'pause', 'entry', 'goto', 'function breakpoint', 'data breakpoint'.
      # @param description [String] The full reason for the event, e.g. 'Paused on exception'. This string is shown in the UI as is and must be translated.
      # @param text [String] Additional information. E.g. if reason is 'exception', text contains the exception name. This string is shown in the UI.
      # @param session_state [Hash] Additional information about the puppet state when the event is raised. See PuppetSessionState::Saved.
      def raise_stopped_event_and_wait(reason, description, text, session_state)
        # Signal a stop event
        assert_flag(:session_paused)

        # Save the state so when the client queries us, we can respond.
        @debug_session.puppet_session_state.saved.update!(session_state)

        @debug_session.send_stopped_event(
          reason,
          'description' => description,
          'text'        => text,
          'threadId'    => @debug_session.puppet_thread_id
        )

        # Spin-wait for the session to be unpaused...
        # TODO - Could be better. Semaphore maybe?
        sleep(0.5) while flag?(:session_paused) && !terminate?
      end

      # Continues a paused debug session
      def continue!
        run_mode.run!
        @debug_session.puppet_session_state.saved.clear!
        unassert_flag(:session_paused)
      end

      # Next steps through a paused debug session
      def next!
        run_mode.next!(@debug_session.puppet_session_state.saved.pops_depth_level)
        @debug_session.puppet_session_state.saved.clear!
        unassert_flag(:session_paused)
      end

      # Steps into a paused debug session
      def step_in!
        run_mode.step_in!
        @debug_session.puppet_session_state.saved.clear!
        unassert_flag(:session_paused)
      end

      # Steps out of a paused debug session
      def step_out!
        run_mode.step_out!(@debug_session.puppet_session_state.saved.pops_depth_level)
        @debug_session.puppet_session_state.saved.clear!
        unassert_flag(:session_paused)
      end
    end
  end
end

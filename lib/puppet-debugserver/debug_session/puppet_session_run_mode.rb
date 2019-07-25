# frozen_string_literal: true

module PuppetDebugServer
  module DebugSession
    # The run mode and configuration for a Debug Session.
    class PuppetSessionRunMode
      # The run mode fo the debug session. Either run, stepin, next, or stepout
      # @return [Symbol]
      attr_accessor :mode

      # Any options associated with the current mode.
      # @option options [Integer] :pops_depth_level The depth of the AST object where the mode was initiated from.
      # @return [Hash]
      attr_accessor :options

      # @param mode See mode. Default is run
      # @param options See options
      def initialize(mode = :run, options = {})
        raise "Invalid mode #{mode}" unless %i[run stepin next stepout].include?(mode)
        @mode = mode
        @options = options

        @run_mode_mutex = Mutex.new
      end

      # Configures the run_mode for "continue until a breakpoint is hit.
      def run!
        @run_mode_mutex.synchronize do
          @mode = :run
          @options = {}
        end
      end

      # Configures the run_mode for "next"-ing through a debug session.
      # @param pops_depth_level [Integer] The depth of the AST object where the next command was initiated from.
      def next!(pops_depth_level)
        @run_mode_mutex.synchronize do
          @mode = :next
          @options = {
            :pops_depth_level => pops_depth_level
          }
        end
      end

      # Configures the run_mode for "stepping in" a debug session.
      def step_in!
        @run_mode_mutex.synchronize do
          @mode = :stepin
          @options = {}
        end
      end

      # Configures the run_mode for "stepping out" a debug session.
      # @param pops_depth_level [Integer] The depth of the AST object  where the step put command was initiated from.
      def step_out!(pops_depth_level)
        @run_mode_mutex.synchronize do
          @mode = :stepout
          @options = {
            :pops_depth_level => pops_depth_level
          }
        end
      end
    end
  end
end

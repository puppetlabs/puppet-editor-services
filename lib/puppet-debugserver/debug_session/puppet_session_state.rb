# frozen_string_literal: true

module PuppetDebugServer
  module DebugSession
    # The actual and saved state of Puppet during a debug session.
    class PuppetSessionState
      # The actual, current state of Puppet during a debug session.
      # @return [PuppetDebugServer::DebugSession::ActualPuppetSessionState]
      attr_reader :actual

      # The state of Puppet when a debug session was paused, typically during a breakpoint or exception.
      # @return [PuppetDebugServer::DebugSession::SavedPuppetSessionState]
      attr_reader :saved

      def initialize
        @actual = ActualPuppetSessionState.new
        @saved = SavedPuppetSessionState.new
      end

      # Clears the saved state. Typically only used when a paused debug session is about to start again.
      def clear!
        @saved.clear!

        self
      end
    end

    # The actual state of Puppet during a debug session
    class ActualPuppetSessionState
      # The depth of AST objects during a catalog compilation.
      # @return [Integer]
      attr_reader :pops_depth_level

      # The compiler used to compile the catalog
      # @return [Puppet::Parser::Compiler]
      attr_reader :compiler

      def initialize
        @pops_depth_level = 0
      end

      # Resets back to initial state. Typically used when a debug session first starts.
      def reset!
        @pops_depth_level = 0
        @compiler = nil
      end

      # Sets the compiler object. Typically set when a debug session begins catalog compilation.
      def update_compiler(value)
        @compiler = value
      end

      # Signals that an AST object is starting to be evaluated. Typically used during catalog compilation.
      def increment_pops_depth
        @pops_depth_level += 1
      end

      # Signals that an AST object has completed evaluated. Typically used during catalog compilation.
      def decrement_pops_depth
        @pops_depth_level -= 1
      end
    end

    # The state of Puppet when a debug session was paused, typically during a breakpoint or exception.
    class SavedPuppetSessionState
      # The exception thrown when the session was paused.
      # @return [Object]
      attr_reader :exception

      # The puppet stacktrace, not ruby stacktrace, when the session was paused.
      # @return [Array<Object>]
      attr_reader :puppet_stacktrace

      # The Pops Object that caused the session to pause.
      # @return [Object]
      attr_reader :pops_target

      # The Pops Scope containing the Pops Object that caused the session to pause.
      # @return [Puppet::Parser::Scope]
      attr_reader :scope

      # The AST depth of the Pops Object that caused the session to pause.
      # @return [Integer]
      attr_reader :pops_depth_level

      # A cache of variable references used to speed up Debug Server VariableReferences queries.
      # @return [Hash<Integer, Object>]
      attr_reader :variable_cache

      def initialize
        @variable_cache = {}
      end

      # Updates the saved session state
      # @see PuppetDebugServer::DebugSession::SavedPuppetSessionState
      # @option options :exception
      # @option options :puppet_stacktrace
      # @option options :pops_target
      # @option options :scope
      # @option options :pops_depth_level
      def update!(options = {})
        @exception         = options[:session_exception] unless options[:session_exception].nil?
        @puppet_stacktrace = options[:puppet_stacktrace] unless options[:puppet_stacktrace].nil?
        @pops_target       = options[:pops_target] unless options[:pops_target].nil?
        @scope             = options[:scope] unless options[:scope].nil?
        @pops_depth_level  = options[:pops_depth_level] unless options[:pops_depth_level].nil?
        self
      end

      # Clears the saved state. Typically used a debug session is un-paused.
      def clear!
        @exception = nil
        @puppet_stacktrace = nil
        @pops_target = nil
        @scope = nil
        @pops_depth_level = nil
        @variable_cache = {}
        self
      end
    end
  end
end

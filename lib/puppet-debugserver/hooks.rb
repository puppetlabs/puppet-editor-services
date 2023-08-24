# frozen_string_literal: true

module PuppetDebugServer
  # This code was inspired from Puppet-Debugger (https://raw.githubusercontent.com/nwops/puppet-debugger/master/lib/puppet-debugger/hooks.rb) which was borrowed from Pry hooks file

  # Both puppet-debugger and pry are licensed with MIT
  # https://raw.githubusercontent.com/nwops/puppet-debugger/master/LICENSE.txt
  # https://raw.githubusercontent.com/pry/pry/master/LICENSE

  class Hooks
    def initialize
      @hooks = Hash.new { |h, k| h[k] = [] }
    end

    # Ensure that duplicates have their @hooks object.
    def initialize_copy
      hooks_dup = @hooks.dup
      @hooks.each do |k, v|
        hooks_dup[k] = v.dup
      end

      @hooks = hooks_dup
    end

    def errors
      @errors ||= []
    end

    # Add a new hook to be executed for the `event_name` event.
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] hook_name The name of the hook.
    # @param [#call] callable The callable.
    # @yield The block to use as the callable (if no `callable` provided).
    # @return [PuppetDebugger::Hooks] The receiver.
    def add_hook(event_name, hook_name, callable = nil, &block)
      event_name = event_name.to_s

      # do not allow duplicates, but allow multiple `nil` hooks
      # (anonymous hooks)
      raise ArgumentError, "Hook with name '#{hook_name}' already defined!" if hook_exist?(event_name, hook_name) && !hook_name.nil?

      raise ArgumentError, 'Must provide a block or callable.' if !block && !callable

      # ensure we only have one anonymous hook
      @hooks[event_name].delete_if { |h, _k| h.nil? } if hook_name.nil?

      if block
        @hooks[event_name] << [hook_name, block]
      elsif callable
        @hooks[event_name] << [hook_name, callable]
      end

      self
    end

    # Execute the list of hooks for the `event_name` event.
    # @param [Symbol] event_name The name of the event.
    # @param [Array] args The arguments to pass to each hook function.
    # @return [Object] The return value of the last executed hook.
    def exec_hook(event_name, *args, &block)
      PuppetDebugServer.log_message(:debug, "Starting to execute hook #{event_name}") unless event_name == :hook_log_message
      @hooks[event_name.to_s].map do |_hook_name, callable|
        begin
          callable.call(*args, &block)
        rescue ::RuntimeError => e
          errors << e
          e
        end
      end.last
      PuppetDebugServer.log_message(:debug, "Finished executing hook #{event_name}") unless event_name == :hook_log_message
    end

    # @param [Symbol] event_name The name of the event.
    # @return [Fixnum] The number of hook functions for `event_name`.
    def hook_count(event_name)
      @hooks[event_name.to_s].size
    end

    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] hook_name The name of the hook
    # @return [#call] a specific hook for a given event.
    def get_hook(event_name, hook_name)
      hook = @hooks[event_name.to_s].find do |current_hook_name, _callable|
        current_hook_name == hook_name
      end
      hook.last if hook
    end

    # @param [Symbol] event_name The name of the event.
    # @return [Hash] The hash of hook names / hook functions.
    # @note Modifying the returned hash does not alter the hooks, use
    # `add_hook`/`delete_hook` for that.
    def get_hooks(event_name)
      Hash[@hooks[event_name.to_s]]
    end

    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] hook_name The name of the hook.
    #   to delete.
    # @return [#call] The deleted hook.
    def delete_hook(event_name, hook_name)
      deleted_callable = nil

      @hooks[event_name.to_s].delete_if do |current_hook_name, callable|
        if current_hook_name == hook_name
          deleted_callable = callable
          true
        else
          false
        end
      end
      deleted_callable
    end

    # Clear all hooks functions for a given event.
    #
    # @param [String] event_name The name of the event.
    # @return [void]
    def clear_event_hooks(event_name)
      @hooks[event_name.to_s] = []
    end

    # @param [Symbol] event_name Name of the event.
    # @param [Symbol] hook_name Name of the hook.
    # @return [Boolean] Whether the hook by the name `hook_name`.
    def hook_exist?(event_name, hook_name)
      @hooks[event_name.to_s].map(&:first).include?(hook_name)
    end

    protected

    attr_reader :hooks
  end
end

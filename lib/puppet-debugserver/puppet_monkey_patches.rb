# frozen_string_literal: true

require 'puppet'

# Note - As much as I'd like to not monkey patch, the debug server supports many versions of the Puppet gem, and the internal
# classes etc. are not exposed easily. Ideally I'd prefer to use a custom compiler and evaluator but it's just not that easy
# to inject them.  Instead we have to resort to monkey patching which is less than ideal

# Monkey patch the Apply application (puppet apply) so that we route the exit
# statement into the debugger first and then exit the puppet thread
require 'puppet/application/apply'
module Puppet
  class Application
    class Apply < Puppet::Application
      def exit(option)
        PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_before_apply_exit, [option])
      end
    end
  end
end

# Monkey patch the compiler so we can wrap our own rescue block around it
# to trap any exceptions that may be of interest to us
require 'puppet/parser/compiler'
module Puppet
  module Parser
    class Compiler
      alias_method :original_compile, :compile

      def compile
        PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_before_compile, [self])
        result = original_compile
        PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_after_compile, [result]) # TODO: This doesn't seem to be needed
        result
      rescue Puppet::ParseErrorWithIssue => e
        # TODO: Potential issue here with 4.10.x not implementing .file on the Positioned class
        # Just re-raise if there is no Puppet manifest file associated with the error
        raise if e.file.nil? || e.line.nil? || e.pos.nil?
        PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_exception, [e])
        raise
      end
    end
  end
end

# Add hooks to the evaluator so we can trap before and after evaluating parts of the syntax tree
require 'puppet/pops/evaluator/evaluator_impl'
module Puppet
  module Pops
    module Evaluator
      class EvaluatorImpl
        alias_method :original_evaluate, :evaluate

        def evaluate(target, scope)
          PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_before_pops_evaluate, [self, target, scope])
          result = original_evaluate(target, scope)
          PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_after_pops_evaluate, [self, target, scope])
          result
        rescue => e # rubocop:disable Style/RescueStandardError Any error could be thrown here
          # Emit non-Puppet related errors to the debug log. We shouldn't get any of these!
          PuppetDebugServer.log_message(:debug, "Error in Puppet::Pops::Evaluator::EvaluatorImpl.evaluate #{e}: #{e.backtrace}") unless e.is_a?(Puppet::Error)
          raise
        end
      end
    end
  end
end

# These come from the original Puppet source
# rubocop:disable Style/PerlBackrefs, Style/EachWithObject
#
# Add a helper method to the PuppetStack object
require 'puppet/pops/puppet_stack'
module Puppet
  module Pops
    module PuppetStack
      # This is very similar to the stacktrace function, but uses the exception
      # backtrace instead of caller()
      def self.stacktrace_from_backtrace(exception)
        exception.backtrace.reduce([]) do |memo, loc|
          if loc =~ /^(.*\.pp)?:([0-9]+):in (`stack'|`block in call_function')/
            memo << [$1.nil? ? 'unknown' : $1, $2.to_i]
          end
          memo
        end
      end
    end
  end
end
# rubocop:enable Style/PerlBackrefs, Style/EachWithObject

# Add hooks to the functions reset so that we can add any needed functions
require 'puppet/parser/functions'
module Puppet
  module Parser
    module Functions
      class << self
        alias_method :original_reset, :reset

        def reset
          result = original_reset
          PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_after_parser_function_reset, [self])
          result
        end
      end
    end
  end
end

# MUST BE LAST!!!!!!
# Add a debugserver log destination type
require 'puppet/util/log'
Puppet::Util::Log.newdesttype :debugserver do
  def handle(msg)
    PuppetDebugServer::PuppetDebugSession.instance.execute_hook(:hook_log_message, [msg])
  end
end

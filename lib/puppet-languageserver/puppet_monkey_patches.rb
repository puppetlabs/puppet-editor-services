# frozen_string_literal: true

# Monkey Patch the Puppet language parser so we can globally lock any changes to the
# global setting Puppet[:tasks].  We need to manage this so we can switch between
# parsing modes.  Unfortunately we can't do this as method parameter, only via the
# global Puppet settings which is not thread safe
$PuppetParserMutex = Mutex.new # rubocop:disable Style/GlobalVars
module Puppet
  module Pops
    module Parser
      class Parser
        def singleton_parse_string(code, task_mode = false, path = nil)
          $PuppetParserMutex.synchronize do # rubocop:disable Style/GlobalVars
            begin
              original_taskmode = Puppet[:tasks] if Puppet.tasks_supported?
              Puppet[:tasks] = task_mode if Puppet.tasks_supported?
              return parse_string(code, path)
            ensure
              Puppet[:tasks] = original_taskmode if Puppet.tasks_supported?
            end
          end
        end
      end
    end
  end
end

module Puppet
  # Tasks first appeared in Puppet 5.4.0
  def self.tasks_supported?
    Gem::Version.new(Puppet.version) >= Gem::Version.new('5.4.0')
  end
end

# MUST BE LAST!!!!!!
# Suppress any warning messages to STDOUT.  It can pollute stdout when running in STDIO mode
Puppet::Util::Log.newdesttype :null_logger do
  def handle(msg)
    PuppetLanguageServer.log_message(:debug, "[PUPPET LOG] [#{msg.level}] #{msg.message}")
  end
end

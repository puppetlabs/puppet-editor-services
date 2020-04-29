# frozen_string_literal: true

# MUST BE LAST!!!!!!
# Suppress any warning messages to STDOUT.  It can pollute stdout when running in STDIO mode
Puppet::Util::Log.newdesttype :null_logger do
  def handle(msg)
    PuppetLanguageServerSidecar.log_message(:debug, "[PUPPET LOG] [#{msg.level}] #{msg.message}")
  end
end

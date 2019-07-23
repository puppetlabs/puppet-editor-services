# Emulate the setup from the root 'puppet-debugserver' file

# Add the debug server into the load path
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'..','lib'))

require 'puppet_debugserver'
# Normally globals are 'bad', but in this case it really should be global to all testing
# code paths
$fixtures_dir = File.join(File.dirname(__FILE__),'fixtures')
$root_dir = File.join(File.dirname(__FILE__),'..','..')
# Currently there is no way to re-initialize the puppet loader so for the moment
# all tests must run off the single puppet config settings instead of per example setting
puppet_settings = ['--vardir',File.join($fixtures_dir,'cache'),
                   '--confdir',File.join($fixtures_dir,'confdir')]
PuppetDebugServer::init_puppet(PuppetDebugServer::CommandLineParser.parse([]))
Puppet.initialize_settings(puppet_settings)

# Custom RSpec Matchers

RSpec::Matchers.define :receive_message_with_request_id_within_timeout do |request_seq_id, timeout = 5|
  match do |client|
    client.wait_for_message_with_request_id(request_seq_id, timeout)
  end

  failure_message do |client|
    message =  "expected that client would event with request id '#{request_seq_id}' event within #{timeout} seconds\n"
    message += "Last 5 messages\n"
    client.received_messages.last(5).each { |item| message += "#{item}\n" }
    message
  end
end

RSpec::Matchers.define :receive_event_within_timeout do |event_name, timeout = 5|
  match do |client|
    client.wait_for_message_with_with_event(event_name, timeout)
  end

  failure_message do |client|
    message = "expected that client would recieve '#{event_name}' event within #{timeout} seconds\n"
    message += "Last 5 messages\n"
    client.received_messages.last(5).each { |item| message += "#{item}\n" }
    message
  end
end

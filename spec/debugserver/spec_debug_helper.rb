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

# Mock ojects
require 'puppet_editor_services/server/base'
class MockServer < PuppetEditorServices::Server::Base
  attr_reader :connection_object
  attr_reader :protocol_object
  attr_reader :handler_object

  def initialize(server_options, connection_options, protocol_options, handler_options)
    connection_options = {} if connection_options.nil?
    connection_options[:class] = MockConnection if connection_options[:class].nil?

    super(server_options, connection_options, protocol_options, handler_options)
    # Build up the object chain
    @connection_object = connection_options[:class].new(self)
    @protocol_object = @connection_object.protocol
    @handler_object = @protocol_object.handler

    # Baic validation that the test fixtures are sane
    raise "Invalid Connection object class" unless @connection_object.is_a?(::PuppetEditorServices::Connection::Base)
    raise "Invalid Protocol object class" unless @protocol_object.is_a?(::PuppetEditorServices::Protocol::Base)
    raise "Invalid Handler object class" unless @handler_object.is_a?(::PuppetEditorServices::Handler::Base)
  end
end

require 'puppet_editor_services/server/base'
class MockConnection < PuppetEditorServices::Connection::Base
  attr_accessor :sent_objects

  def send_data(data)
    @sent_objects = [] if @sent_objects.nil?
    # Strip the Content Header
    stripped_data = data.slice(data.index("\r\n\r\n") + 4 ..-1)
    @sent_objects << JSON.parse(stripped_data)
    true
  end
end

require 'puppet_editor_services/protocol/debug_adapter'
class MockProtocol < PuppetEditorServices::Protocol::DebugAdapter
  def receive_mock_string(content)
    receive_json_message_as_string(content)
  end
end

require_relative '../spec_helper.rb'
# Emulate the setup from the root 'puppet-languageserver' file
root = File.join(File.dirname(__FILE__),'..','..')
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))
# Add the vendored gems into the load path
$LOAD_PATH.unshift(File.join(root,'vendor','puppet-lint','lib'))
$LOAD_PATH.unshift(File.join(root,'vendor','molinillo','lib'))
$LOAD_PATH.unshift(File.join(root,'vendor','puppetfile-resolver','lib'))

require 'puppet_languageserver'
$fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')
$root_dir = File.join(File.dirname(__FILE__), '..', '..')
# Currently there is no way to re-initialize the puppet loader so for the moment
# all tests must run off the single puppet config settings instead of per example setting
server_options = PuppetLanguageServer::CommandLineParser.parse(['--slow-start'])
server_options[:puppet_settings] = ['--vardir',File.join($fixtures_dir,'cache'),
                                    '--confdir',File.join($fixtures_dir,'confdir')]
PuppetLanguageServer::init_puppet(server_options)

def populate_cache(cache)
  if $exemplar_cache.nil?
    session_state = PuppetLanguageServer::ClientSessionState.new(nil, :connection_id => '123')
    session_state.load_static_data!(false)
    $exemplar_cache = session_state.object_cache

    # Emulate the result of running a sidecar job to load all of puppet.
    # This comes from a saved JSON fixtures file to speed up testing.
    puppet_data = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
    path = File.join($fixtures_dir, 'puppet_object_cache.json')
    data = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(File.open(path, 'rb:UTF-8') { |f| f.read })
    data.each_list { |_, list| puppet_data.concat!(list) }

    $exemplar_cache.import_sidecar_list!(puppet_data.classes,   :class,    :default)
    $exemplar_cache.import_sidecar_list!(puppet_data.datatypes, :datatype, :default)
    $exemplar_cache.import_sidecar_list!(puppet_data.functions, :function, :default)
    $exemplar_cache.import_sidecar_list!(puppet_data.types,     :type,     :default)

    # Emulate the result of running a sidecar job to load facter.
    # This comes from a saved JSON fixtures file to speed up testing.
    path = File.join($fixtures_dir, 'fact_object_cache.json')
    data = PuppetLanguageServer::Sidecar::Protocol::FactList.new.from_json!(File.open(path, 'rb:UTF-8') { |f| f.read })
    $exemplar_cache.import_sidecar_list!(data, :fact, :default)
  end

  # This is a little brittle, but will work for the moment.
  cache.instance_variable_set(
    :@inmemory_cache,
    $exemplar_cache.instance_variable_get(:@inmemory_cache).dup
  )
  nil
end

# Sidecar Protocol Helpers
def add_default_basepuppetobject_values!(value)
  value.key = :key
  value.calling_source = 'calling_source'
  value.source = 'source'
  value.line = 1
  value.char = 2
  value.length = 3
  value
end

def add_random_basepuppetobject_values!(value)
  value.key = ('key' + rand(1000).to_s).intern
  value.calling_source = 'calling_source' + rand(1000).to_s
  value.source = 'source' + rand(1000).to_s
  value.line = rand(1000)
  value.char = rand(1000)
  value.length = rand(1000)
  value
end

def random_sidecar_fact(key = nil)
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::Fact.new())
  result.key = key unless key.nil?
  result.value = 'value' + rand(1000).to_s
  result
end

def random_sidecar_puppet_class(key = nil)
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new())
  result.key = key unless key.nil?
  result.doc = 'doc' + rand(1000).to_s
  result.parameters = {
    "attr_name1" => { :type => "Optional[String]", :doc => 'attr_doc1' },
    "attr_name2" => { :type => "String", :doc => 'attr_doc2' }
  }
  result
end

def random_sidecar_puppet_datatype(key = nil)
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new())
  result.key = key unless key.nil?
  result.doc = 'doc' + rand(1000).to_s
  result.alias_of = "String[1, #{rand(255)}]"
  result.attributes << random_sidecar_puppet_datatype_attribute
  result.attributes << random_sidecar_puppet_datatype_attribute
  result.attributes << random_sidecar_puppet_datatype_attribute
  result.is_type_alias = rand(255) < 128
  result
end

def random_sidecar_puppet_datatype_attribute
  result = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeAttribute.new
  result.doc = 'doc' + rand(1000).to_s
  result.default_value = 'default' + rand(1000).to_s
  result.types = 'String'
  result
end

def random_sidecar_puppet_function(key = nil)
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new())
  result.key = key unless key.nil?
  result.doc = 'doc' + rand(1000).to_s
  result.function_version = rand(1) + 3
  result.signatures << random_sidecar_puppet_function_signature
  result.signatures << random_sidecar_puppet_function_signature
  result.signatures << random_sidecar_puppet_function_signature
  result
end

def random_sidecar_puppet_function_signature
  result = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignature.new
  result.key = 'key' + rand(1000).to_s + '(a,b,c)'
  result.doc = 'doc' + rand(1000).to_s
  result.return_types = [rand(1000).to_s, rand(1000).to_s, rand(1000).to_s]
  result.parameters << random_sidecar_puppet_function_signature_parameter
  result.parameters << random_sidecar_puppet_function_signature_parameter
  result.parameters << random_sidecar_puppet_function_signature_parameter
  result
end

def random_sidecar_puppet_function_signature_parameter
  result = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureParameter.new
  result.name = 'param' + rand(1000).to_s
  result.types = [rand(1000).to_s, rand(1000).to_s]
  result.doc = result.name + ' documentation'
  result.signature_key_offset = rand(1000)
  result.signature_key_length = rand(1000)
  result
end

def random_sidecar_puppet_type(key = nil)
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetType.new())
  result.key = key unless key.nil?
  result.doc = 'doc' + rand(1000).to_s
  result.attributes = {
    :attr_name1 => { :type => :attr_type, :doc => 'attr_doc1', :required? => false, :isnamevar? => true },
    :attr_name2 => { :type => :attr_type, :doc => 'attr_doc2', :required? => false, :isnamevar? => false }
  }
  result
end

def random_sidecar_resource(typename = nil, title = nil)
  typename = 'randomtype' if typename.nil?
  title = rand(1000).to_s if title.nil?
  result = PuppetLanguageServer::Sidecar::Protocol::Resource.new()
  result.manifest = "#{typename} { '#{title}':\n  id => #{rand(1000).to_s}\n}"
  result
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
  attr_accessor :buffer

  def send_data(data)
    @buffer = '' if @buffer.nil?
    @buffer += data
    true
  end
end

class MockMessageHandler < PuppetEditorServices::Handler::Base
  def request_initialize(*_); end

  def notification_initialized(*_); end

  def response_mock(*_); end
end

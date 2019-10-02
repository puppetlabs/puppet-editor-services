# Emulate the setup from the root 'puppet-languageserver' file

root = File.join(File.dirname(__FILE__),'..','..')
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))
# Add the vendored gems into the load path
$LOAD_PATH.unshift(File.join(root,'vendor','puppet-lint','lib'))

require 'puppet_languageserver'
$fixtures_dir = File.join(File.dirname(__FILE__),'fixtures')

# Currently there is no way to re-initialize the puppet loader so for the moment
# all tests must run off the single puppet config settings instead of per example setting
server_options = PuppetLanguageServer::CommandLineParser.parse(['--slow-start'])
server_options[:puppet_settings] = ['--vardir',File.join($fixtures_dir,'cache'),
                                    '--confdir',File.join($fixtures_dir,'confdir')]
PuppetLanguageServer::init_puppet(server_options)

def wait_for_puppet_loading
  interation = 0
  loop do
    break if PuppetLanguageServer::PuppetHelper.default_functions_loaded? &&
             PuppetLanguageServer::PuppetHelper.default_types_loaded? &&
             PuppetLanguageServer::PuppetHelper.default_classes_loaded? &&
             PuppetLanguageServer::PuppetHelper.default_datatypes_loaded?
    sleep(1)
    interation += 1
    next if interation < 90
    raise <<-ERRORMSG
            Puppet has not be initialised in time:
            functions_loaded? = #{PuppetLanguageServer::PuppetHelper.default_functions_loaded?}
            types_loaded? = #{PuppetLanguageServer::PuppetHelper.default_types_loaded?}
            classes_loaded? = #{PuppetLanguageServer::PuppetHelper.default_classes_loaded?}
            datatypes_loaded? = #{PuppetLanguageServer::PuppetHelper.default_datatypes_loaded?}
          ERRORMSG
  end
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

def random_sidecar_puppet_datatype
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new())
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

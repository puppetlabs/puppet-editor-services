# Emulate the setup from the root 'puppet-languageserver' file

root = File.join(File.dirname(__FILE__),'..','..')
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))
# Add the vendored gems into the load path
$LOAD_PATH.unshift(File.join(root,'vendor','puppet-lint','lib'))

require 'puppet-languageserver'
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
    break if PuppetLanguageServer::PuppetHelper.functions_loaded? &&
             PuppetLanguageServer::PuppetHelper.types_loaded? &&
             PuppetLanguageServer::PuppetHelper.classes_loaded?
    sleep(1)
    interation += 1
    next if interation < 30
    raise <<-ERRORMSG
            Puppet has not be initialised in time:
            functions_loaded? = #{PuppetLanguageServer::PuppetHelper.functions_loaded?}
            types_loaded? = #{PuppetLanguageServer::PuppetHelper.types_loaded?}
            classes_loaded? = #{PuppetLanguageServer::PuppetHelper.classes_loaded?}
          ERRORMSG
  end
end

# Custom RSpec Matchers
RSpec::Matchers.define :be_completion_item_with_type do |value|
  value = [value] unless value.is_a?(Array)

  match { |actual| value.include?(actual['data']['type']) }

  description do
    "be a Completion Item with a data type in the list of #{value}"
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

def random_sidecar_puppet_class
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new())
  result
end

def random_sidecar_puppet_function
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new())
  result.doc = 'doc' + rand(1000).to_s
  result.arity = rand(1000)
  result.type = ('type' + rand(1000).to_s).intern
  result
end

def random_sidecar_puppet_type
  result = add_random_basepuppetobject_values!(PuppetLanguageServer::Sidecar::Protocol::PuppetType.new())
  result.doc = 'doc' + rand(1000).to_s
  result.attributes = {
    :attr_name1 => { :type => :attr_type, :doc => 'attr_doc1', :required? => false },
    :attr_name2 => { :type => :attr_type, :doc => 'attr_doc2', :required? => false }
  }
  result
end

# Mock ojects
class MockConnection < PuppetEditorServices::SimpleServerConnectionBase
  def send_data(data)
    true
  end
end

class MockJSONRPCHandler < PuppetLanguageServer::JSONRPCHandler
  def initialize(options = {})
    super(options)

    @client_connection = MockConnection.new
  end

  def receive_data(data)
  end
end

class MockRelationshipGraph
  attr_accessor :vertices
  def initialize()
  end
end

class MockResource
  attr_accessor :title

  def initialize(type_name = 'type' + rand(65536).to_s, title = 'resource' + rand(65536).to_s)
    @title = title
    @type = type_name
  end

  def to_manifest
    <<-HEREDOC
#{@type} { '#{@title}':
  ensure => present
}
    HEREDOC
  end
end

# frozen_string_literal: true

root = File.join(__dir__,'..',)
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))

FIXTURES_DIR = File.join(__dir__,'fixtures')

# A cache which we can preload for the purposes of testing, mimicing
# Local modules
require 'puppetfile-resolver/cache/base'
class MockLocalModuleCache < PuppetfileResolver::Cache::Base
  def initialize
    super(nil)

    @mock_modules = {}
  end

  def exist?(name)
    result = super
    return result if result
    @mock_modules.key?(name)
  end

  def load(name)
    result = super
    return result unless result.nil?

    @mock_modules[name]
  end

  def add_local_module_spec(name, dependencies = [], puppet_requirement = nil, version = '1.0.0')
    requirements = []
    requirements << { name: 'puppet', version_requirement: puppet_requirement } unless puppet_requirement.nil?
    spec = PuppetfileResolver::Models::ModuleSpecification.new(
      name: name,
      origin: :local,
      version: version,
      metadata: {
        dependencies: dependencies,
        requirements: requirements
      }
    )
    # Note - This is quite implementation dependant so could be fragile.
    # Yes, I know it's expecting a Dependency object, but the spec is fine.
    id = PuppetfileResolver::SpecSearchers::Common.dependency_cache_id(PuppetfileResolver::SpecSearchers::Local, spec)
    @mock_modules[id] = [] if @mock_modules[id].nil?
    @mock_modules[id] << spec
  end
end

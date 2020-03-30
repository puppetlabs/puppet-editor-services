$LOAD_PATH.push(File.expand_path('../lib', __FILE__))
require 'puppetfile-resolver/version'

Gem::Specification.new do |spec|
  spec.name = 'puppetfile-resolver'
  spec.version = PuppetfileResolver::VERSION.dup
  spec.authors = ['Glenn Sarti']
  spec.email = ['glennsarti@users.noreply.github.com']
  spec.license = 'Apache-2.0'
  spec.homepage = 'https://glennsarti.github.io/puppetfile-resolver/'
  spec.summary = 'Dependency resolver for Puppetfiles'
  spec.description = 'Resolves the Puppet Modules in a Puppetfile with a full dependency graph, including Puppet version checkspec.'

  spec.files = Dir['puppetfile-cli.rb', 'README.md', 'LICENSE', 'lib/**/*']
  spec.test_files = Dir['spec/**/*']
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1.9'

  spec.add_runtime_dependency 'molinillo', '~> 0.6'
  spec.add_runtime_dependency 'semantic_puppet', '~> 1.0'
end

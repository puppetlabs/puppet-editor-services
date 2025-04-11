# frozen_string_literal: true
require_relative 'lib/puppet_editor_services/version'
require 'rake'

Gem::Specification.new do |s|
  s.name           = 'puppet-editor-services'
  s.version        = PuppetEditorServices.version
  s.authors        = ['Puppet']
  s.email          = ['support@puppet.com']
  s.summary       = 'Puppet Language Server for editors'
  s.description = <<~EOF
    A ruby based implementation of a Language Server and Debug Server for the
    Puppet Language. Integrate this into your editor to benefit from full Puppet
    Language support, such as syntax hightlighting, linting, hover support and more.
  EOF
  s.homepage    = 'https://github.com/puppetlabs/puppet-editor-services'
  s.required_ruby_version = '>= 3.1.0'
  s.executables = %w[ puppet-debugserver puppet-languageserver puppet-languageserver-sidecar ]
  s.files          = FileList['lib/**/*.rb',
                              'bin/*',
                              '[A-Z]*'].to_a
  s.license        = 'Apache-2.0'
  s.add_runtime_dependency 'puppet-lint', '~> 4.0'
  s.add_runtime_dependency 'hiera-eyaml', '~> 2.1'
  s.add_runtime_dependency 'puppetfile-resolver', '~> 0.6'
  s.add_runtime_dependency 'molinillo', '~> 0.6'
  s.add_runtime_dependency 'puppet-strings', '~> 4.0'
  s.add_runtime_dependency 'yard', '~> 0.9'
end

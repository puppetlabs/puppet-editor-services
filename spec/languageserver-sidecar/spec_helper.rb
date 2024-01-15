require_relative '../spec_helper.rb'

# Emulate the setup from the root 'puppet-languageserver' file

root = File.join(File.dirname(__FILE__),'..','..')
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))
# Add the vendored gems into the load path
$LOAD_PATH.unshift(File.join(root, 'vendor', 'yard', 'lib'))
$LOAD_PATH.unshift(File.join(root, 'vendor', 'puppet-strings', 'lib'))

require 'puppet_languageserver_sidecar'
# rubocop:disable Style/GlobalVars
$fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')
# rubocop:enable Style/GlobalVars

# Currently there is no way to re-initialize the puppet loader so for the moment
# all tests must run off the single puppet config settings instead of per example setting
sidecar_options = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop'])

PuppetLanguageServerSidecar.init_puppet_sidecar(sidecar_options)

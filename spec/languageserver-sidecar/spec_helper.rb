# Emulate the setup from the root 'puppet-languageserver' file

root = File.join(File.dirname(__FILE__),'..','..')
# Add the language server into the load path
$LOAD_PATH.unshift(File.join(root,'lib'))
# Add the vendored gems into the load path

require 'puppet-languageserver-sidecar'
# rubocop:disable Style/GlobalVars
$fixtures_dir = File.join(File.dirname(__FILE__), 'fixtures')

# Currently there is no way to re-initialize the puppet loader so for the moment
# all tests must run off the single puppet config settings instead of per example setting
server_options = PuppetLanguageServer::CommandLineParser.parse(['--slow-start'])
server_options[:puppet_settings] = ['--vardir', File.join($fixtures_dir, 'cache'),
                                    '--confdir', File.join($fixtures_dir, 'confdir')]
# rubocop:enable Style/GlobalVars

PuppetLanguageServerSidecar.init_puppet_sidecar(server_options)

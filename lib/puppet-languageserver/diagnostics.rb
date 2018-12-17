module PuppetLanguageServer
  module Diagnostics
    def self.create_document
<<-DIAG
# Puppet Editor Services"

Editor Services version: #{PuppetEditorServices.version}\n
Ruby version: #{RUBY_VERSION}\n
Puppet version: #{Puppet.version}\n
Facter version: #{Facter.version}\n

## Puppet Settings

#{Puppet.settings.each_key.sort.map { |key| "- #{key}: #{Puppet.settings[key]}" }.join("\n")}

## Document Store

Root path: #{PuppetLanguageServer::DocumentStore.store_root_path}\n
Contains metadata.json: #{PuppetLanguageServer::DocumentStore.store_has_module_metadata?}\n
Contains environment.conf: #{PuppetLanguageServer::DocumentStore.store_has_environmentconf?}\n
Loaded documents:
- #{PuppetLanguageServer::DocumentStore.document_uris.join("\n- ")}

## Object Cache

Default facts loaded: #{PuppetLanguageServer::FacterHelper.facts_loaded?}\n
Default functions loaded: #{PuppetLanguageServer::PuppetHelper.default_functions_loaded?}\n
Default types loaded: #{PuppetLanguageServer::PuppetHelper.default_types_loaded?}\n
Default classes loaded: #{PuppetLanguageServer::PuppetHelper.default_classes_loaded?}\n

DIAG
    end
  end
end

# TODO Add object cache list
# TODO Add sidecar and validation settings
# TODO see if I can get ARGS

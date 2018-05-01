%w[
  epp/validation_provider
  manifest/completion_provider
  manifest/definition_provider
  manifest/document_validator
  manifest/hover_provider
].each do |lib|
  begin
    require "puppet-languageserver/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

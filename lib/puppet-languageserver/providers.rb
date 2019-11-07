# frozen_string_literal: true

%w[
  epp/validation_provider
  manifest/completion_provider
  manifest/definition_provider
  manifest/document_symbol_provider
  manifest/format_on_type_provider
  manifest/signature_provider
  manifest/validation_provider
  manifest/hover_provider
  puppetfile/validation_provider
].each do |lib|
  begin
    require "puppet-languageserver/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

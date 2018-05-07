%w[
  epp/validation_provider
  manifest/completion_provider
  manifest/definition_provider
  manifest/validation_provider
  manifest/hover_provider
  puppetfile/r10k/puppetfile
  puppetfile/validation_provider
].each do |lib|
  begin
    require "puppet-languageserver/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

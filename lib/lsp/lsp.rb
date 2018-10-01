%w[lsp_base lsp_enums lsp_protocol lsp_types lsp_custom].each do |lib|
  begin
    require "lsp/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

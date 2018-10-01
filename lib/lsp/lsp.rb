%w[lsp_base].each do |lib|
  begin
    require "lsp/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

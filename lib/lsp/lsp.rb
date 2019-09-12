# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# See tools/lsp_introspect/index.js

%w[lsp_base lsp_custom lsp_types lsp_enums lsp_protocol_colorprovider lsp_protocol_configuration lsp_protocol lsp_protocol_declaration lsp_protocol_foldingrange lsp_protocol_implementation lsp_protocol_typedefinition lsp_protocol_workspacefolders].each do |lib|
  begin
    require "lsp/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

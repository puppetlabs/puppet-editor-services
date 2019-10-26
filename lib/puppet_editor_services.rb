# frozen_string_literal: true

%w[logging version simple_base simple_tcp_server simple_stdio_server].each do |lib|
  begin
    require "puppet_editor_services/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), 'puppet_editor_services', 'lib', lib))
  end
end

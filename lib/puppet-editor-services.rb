%w[logging version simple_tcp_server].each do |lib|
  begin
    require "puppet-editor-services/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-editor-services', 'lib', lib))
  end
end

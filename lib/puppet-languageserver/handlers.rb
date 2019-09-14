# frozen_string_literal: true

%w[
  handlers/pdk_handler.rb
].each do |lib|
  begin
    require "puppet-languageserver/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

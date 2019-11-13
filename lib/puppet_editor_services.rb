# frozen_string_literal: true

%w[
  logging
  version
].each do |lib|
  require "puppet_editor_services/#{lib}"
end

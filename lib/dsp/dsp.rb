# frozen_string_literal: true

%w[dsp_base dsp_protocol].each do |lib|
  begin
    require "dsp/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(__dir__, lib))
  end
end

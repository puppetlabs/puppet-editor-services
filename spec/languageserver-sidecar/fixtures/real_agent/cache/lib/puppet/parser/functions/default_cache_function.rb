module Puppet::Parser::Functions
  newfunction(:default_cache_function, :type => :rvalue, :doc => <<-EOS
A function that should appear in the list of default functions
    EOS
  ) do |arguments|
    # Do nothing
  end
end

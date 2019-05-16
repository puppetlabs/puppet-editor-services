# Example function using the Puppet 4 API in a module
# This should be loaded in the module namespace
Puppet::Functions.create_function(:'profile::pup4_envprofile_function') do
  # @return [Array<String>]
  def pup4_envprofile_function
    'pup4_envprofile_function result'
  end
end

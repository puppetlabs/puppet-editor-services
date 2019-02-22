# Example function using the Puppet 4 API
# This should be loaded in the module called 'modname' namespace
Puppet::Functions.create_function(:'modname::default_mod_pup4_function') do
  # @return [Array<String>]
  def default_mod_pup4_function
    'default_env_pup4_function result'
  end
end

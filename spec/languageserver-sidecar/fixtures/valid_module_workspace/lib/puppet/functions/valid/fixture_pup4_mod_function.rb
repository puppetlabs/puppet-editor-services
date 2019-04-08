# Example function using the Puppet 4 API in a module
# This should be loaded in the module namespace
Puppet::Functions.create_function(:'valid::fixture_pup4_mod_function') do
  # @return [Array<String>]
  def fixture_pup4_mod_function
    'fixture_pup4_mod_function result'
  end
end

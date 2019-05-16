# Example function using the Puppet 4 API in a module
# This should not be loaded in the module namespace
Puppet::Functions.create_function(:'badname::fixture_pup4_badname_function') do
  # @return [Array<String>]
  def fixture_pup4_badname_function
    'fixture_pup4_badname_function result'
  end
end

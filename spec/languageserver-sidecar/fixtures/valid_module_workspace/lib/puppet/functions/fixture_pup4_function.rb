# Example function using the Puppet 4 API in a module
# This should be loaded as global namespace function
Puppet::Functions.create_function(:fixture_pup4_function) do
  # @return [Array<String>]
  def fixture_pup4_function
    'fixture_pup4_function result'
  end
end

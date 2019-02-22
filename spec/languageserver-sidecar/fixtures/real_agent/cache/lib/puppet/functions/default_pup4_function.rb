# Example function using the Puppet 4 API
# This should be loaded
Puppet::Functions.create_function(:default_pup4_function) do
  # @return [Array<String>]
  def default_pup4_function
    'default_pup4_function result'
  end
end

# Example function using the Puppet 4 API in a module
# This should not be loaded in the environment namespace
Puppet::Functions.create_function(:'badname::pup4_function') do
  # @return [Array<String>]
  def pup4_function
    'pup4_function result'
  end
end

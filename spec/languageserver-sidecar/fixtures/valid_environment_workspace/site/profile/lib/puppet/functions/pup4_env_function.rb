# Example function using the Puppet 4 API in a module
# ??? This should be loaded as global namespace function
Puppet::Functions.create_function(:pup4_env_function) do
  # @return [Array<String>]
  def pup4_env_function
    'pup4_env_function result'
  end
end

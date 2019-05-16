# Example function using the Puppet 4 API
# This should be loaded in the environment namespace
Puppet::Functions.create_function(:'environment::default_env_pup4_function') do
  # @return [Array<String>]
  def default_env_pup4_function
    'default_env_pup4_function result'
  end
end

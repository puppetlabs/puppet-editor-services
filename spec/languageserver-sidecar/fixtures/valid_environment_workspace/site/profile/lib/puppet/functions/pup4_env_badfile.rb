require 'a_bad_gem_that_does_not_exist'

# Example function using the Puppet 4 API in a module
# This should not be loaded
Puppet::Functions.create_function(:pup4_env_badfile) do
  # @return [Array<String>]
  def pup4_env_badfile
    'pup4_env_badfile result'
  end
end

# Example function using the Puppet 4 API in a module
# This should be loaded but never actually successfully invoke
Puppet::Functions.create_function(:pup4_env_badfunction) do
  # @return [Array<String>]
  def pup4_env_badfunction
    require 'a_bad_gem_that_does_not_exist'
    'pup4_env_badfunction result'
  end
end

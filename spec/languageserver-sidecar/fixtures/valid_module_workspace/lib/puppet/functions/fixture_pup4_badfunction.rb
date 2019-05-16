# Example function using the Puppet 4 API in a module
# This should be loaded but never actually successfully invoke
Puppet::Functions.create_function(:fixture_pup4_badfunction) do
  # @return [Array<String>]
  def fixture_pup4_badfunction
    require 'a_bad_gem_that_does_not_exist'
    'fixture_pup4_badfunction result'
  end
end

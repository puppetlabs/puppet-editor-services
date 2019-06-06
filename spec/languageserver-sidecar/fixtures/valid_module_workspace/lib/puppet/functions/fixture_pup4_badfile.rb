require 'a_bad_gem_that_does_not_exist'

# Example function using the Puppet 4 API in a module
# This should not be loaded
Puppet::Functions.create_function(:fixture_pup4_badfile) do
  # @return [Array<String>]
  def fixture_pup4_badfile
    'fixture_pup4_badfile result'
  end
end

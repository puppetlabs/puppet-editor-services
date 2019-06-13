# Example function using the Puppet 4 API in a module
# This should be loaded as global namespace function
Puppet::Functions.create_function(:fixture_pup4_function) do
  dispatch :method1 do
    param 'String', :a_string
    optional_block_param :block
    return_type 'Array<String>'
  end

  # Does things with numbers
  # @param an_integer The first number.
  # @param values_to_average Zero or more additional numbers.
  # @return [Array] Nothing useful
  # @example Subtracting two arrays.
  #   fixture_pup4_function(3, 2, 1) => ['Hello']
  dispatch :method2 do
    param 'Integer', :an_integer
    optional_repeated_param 'Numeric', :values_to_average
    return_type 'Array<String>'
  end

  def method1(a_string, &block)
    ['fixture_pup4_function result']
  end

  def method2(an_integer, *values_to_average)
    ['fixture_pup4_function result']
  end
end

# Note that method1 has no documentation.  This is for testing default documentation

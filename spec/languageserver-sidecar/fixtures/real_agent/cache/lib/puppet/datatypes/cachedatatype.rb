# An example Puppet Data Type in Ruby.
#
# @param arg1 [String[1]] A message parameter.
# @param arg2 Optional String parameter. Defaults to 'param'.
# @param badarg3 Optional String parameter. Defaults to 'param'.
Puppet::DataTypes.create_type('RubyDataType') do
  interface <<-PUPPET
    attributes => {
      arg1   => Numeric,
      missingarg1   => { type => OString[1], value => "missing" },
      arg2  => { type => Optional[String[1]], value => "param" }
    }
    PUPPET
end

# A Puppet Data Type in Ruby.
#
# @param arg1 [String] A message parameter.
# @param arg2 An Optional Numeric parameter.
Puppet::DataTypes.create_type('ValidModuleDataType') do
  interface <<-PUPPET
    attributes => {
      arg1  => { type => String, value => "defaultvalue" },
      arg2  => { type => Optional[Numeric], value => 12 }
    }
    PUPPET
end

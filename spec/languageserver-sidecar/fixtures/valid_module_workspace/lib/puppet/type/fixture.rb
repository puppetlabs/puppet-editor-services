Puppet::Type.newtype(:fixture) do
  @doc = 'doc_type_fixture'

  newparam(:name) do
    desc 'name_parameter'
    isnamevar
  end

  newproperty(:when) do
    desc "when_property"
  end
end

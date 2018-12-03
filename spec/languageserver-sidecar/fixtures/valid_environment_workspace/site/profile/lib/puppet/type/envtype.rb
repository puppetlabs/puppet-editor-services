Puppet::Type.newtype(:envtype) do
  @doc = 'doc_type_fixture'

  newparam(:name) do
    desc 'name_env_parameter'
    isnamevar
  end

  newproperty(:when) do
    desc "when_env_property"
  end
end

Puppet::Type.newtype(:default_type) do
  @doc = "Sets the global defaults for all printers on the system."

  ensurable

  newparam(:name, :isnamevar => true) do
    desc "The name of the default_type."
  end
end

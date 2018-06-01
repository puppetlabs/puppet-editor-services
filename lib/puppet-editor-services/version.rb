module PuppetEditorServices
  PUPPETEDITORSERVICESVERSION = '0.12.0'.freeze unless defined? PUPPETEDITORSERVICESVERSION

  # @api public
  #
  # @return [String] containing the editor services version, e.g. "0.4.0"
  def self.version
    return @editor_services_version if @editor_services_version

    version_file = File.join(File.dirname(__FILE__), 'VERSION')
    version = read_version_file(version_file)

    @editor_services_version = version ? version : PUPPETEDITORSERVICESVERSION
  end

  # Sets the editor services version
  # Typically only used in testing
  #
  # @return [void]
  #
  # @api private
  def self.version=(version)
    @editor_services_version = version
  end

  # @api private
  #
  # @return [String] the version -- for example: "0.4.0" or nil if the VERSION
  #   file does not exist.
  def self.read_version_file(path)
    File.read(path).chomp if File.exist?(path)
  end
  private_class_method :read_version_file
end

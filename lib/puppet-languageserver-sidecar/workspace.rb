# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module Workspace
    @root_path = nil
    @has_module_metadata = false
    @has_environmentconf = false

    def self.detect_workspace(path)
      result = process_workspace(path)
      @root_path = result[:root_path]
      @has_module_metadata = result[:has_metadatajson]
      @has_environmentconf = result[:has_environmentconf]
    end

    def self.root_path
      @root_path
    end

    def self.has_module_metadata? # rubocop:disable Naming/PredicateName
      @has_module_metadata
    end

    def self.has_environmentconf? # rubocop:disable Naming/PredicateName
      @has_environmentconf
    end

    # Given a path, locate a metadata.json or environment.conf file to determine where the
    # root of the module/control repo actually is
    def self.find_root_path(path)
      return nil if path.nil?
      filepath = File.expand_path(path)

      if dir_exist?(filepath)
        directory = filepath
      elsif file_exist?(filepath)
        directory = File.dirname(filepath)
      else
        return nil
      end

      until directory.nil?
        break if file_exist?(File.join(directory, 'metadata.json')) || file_exist?(File.join(directory, 'environment.conf'))
        parent = File.dirname(directory)
        # If the parent is the same as the original, then we've reached the end of the path chain
        if parent == directory
          directory = nil
        else
          directory = parent
        end
      end

      directory
    end
    private_class_method :find_root_path

    def self.process_workspace(path)
      result = {
        :root_path           => nil,
        :has_environmentconf => false,
        :has_metadatajson    => false
      }
      return result if path.nil?

      root_path = find_root_path(path)
      if root_path.nil?
        result[:root_path] = path
      else
        result[:root_path] = root_path
        result[:has_metadatajson] = file_exist?(File.join(root_path, 'metadata.json'))
        result[:has_environmentconf] = file_exist?(File.join(root_path, 'environment.conf'))
      end
      result
    end
    private_class_method :process_workspace

    def self.file_exist?(path)
      File.exist?(path) && !File.directory?(path)
    end
    private_class_method :file_exist?

    def self.dir_exist?(path)
      Dir.exist?(path)
    end
    private_class_method :dir_exist?
  end
end

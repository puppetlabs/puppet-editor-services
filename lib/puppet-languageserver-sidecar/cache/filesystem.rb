# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module Cache
    class FileSystem < Base
      attr_reader :cache_dir

      def initialize(_options = {})
        super
        require 'digest'
        require 'json'
        require 'tmpdir'

        @cache_dir = File.join(Dir.tmpdir, 'puppet-vscode-cache')
        begin
          Dir.mkdir(@cache_dir) unless Dir.exist?(@cache_dir)
        rescue Errno::ENOENT => e
          PuppetLanguageServerSidecar.log_message(:error, "[PuppetLanguageServerSidecar::Cache::FileSystem] An error occured while creating file cache.  Disabling cache: #{e}")
          @cache_dir = nil
        end
      end

      def active?
        !@cache_dir.nil?
      end

      def load(absolute_path, section)
        return nil unless active?
        file_key = file_key(absolute_path, section)
        cache_file = File.join(cache_dir, cache_filename(file_key))

        content = read_file(cache_file)
        return nil if content.nil?

        json_obj = JSON.parse(content)
        return nil if json_obj.nil?

        # Check that this is from the same language server version
        unless json_obj['sidecar_version'] == PuppetLanguageServerSidecar.version
          PuppetLanguageServerSidecar.log_message(:debug, "[PuppetLanguageServerSidecar::Cache::FileSystem.load] Error loading #{absolute_path}: Expected sidecar_version version #{PuppetLanguageServerSidecar.version} but found #{json_obj['sidecar_version']}")
          return nil
        end
        # Check that the source file hash matches
        content_hash = calculate_hash(absolute_path)
        if json_obj['file_hash'] != content_hash
          PuppetLanguageServerSidecar.log_message(:debug, "[PuppetLanguageServerSidecar::Cache::FileSystem.load] Error loading #{absolute_path}: Expected file_hash of #{content_hash} but found #{json_obj['file_hash']}")
          return nil
        end
        PuppetLanguageServerSidecar.log_message(:debug, "[PuppetLanguageServerSidecar::Cache::FileSystem.load] Loading #{absolute_path} from cache")

        json_obj['data']
      rescue RuntimeError => e
        PuppetLanguageServerSidecar.log_message(:debug, "[PuppetLanguageServerSidecar::Cache::FileSystem.load] Error loading #{absolute_path}: #{e}")
        raise
      end

      def save(absolute_path, section, content_string)
        return false unless active?
        file_key = file_key(absolute_path, section)
        cache_file = File.join(cache_dir, cache_filename(file_key))

        content = { 'data' => content_string }
        # Inject metadata
        content['sidecar_version'] = PuppetLanguageServerSidecar.version
        content['file_hash'] = calculate_hash(absolute_path)
        content['created'] = Time.now.utc.strftime('%FT%T')
        content['path'] = absolute_path
        content['section'] = section

        PuppetLanguageServerSidecar.log_message(:debug, "[PuppetLanguageServerSidecar::Cache::FileSystem.save] Saving #{absolute_path} to cache")
        save_file(cache_file, content.to_json)
      end

      def clear!
        return unless active?
        PuppetLanguageServerSidecar.log_message(:warn, '[PuppetLanguageServerSidecar::Cache::FileSystem.clear] Filesystem based cache is being cleared')
        FileUtils.rm(Dir.glob(File.join(cache_dir, '*')), :force => true)
      end

      private

      def file_key(filepath, section)
        # Strictly speaking some file systems are case sensitive but ruby/puppet throws a fit
        # with naming if you do
        filepath.downcase + File::SEPARATOR + section
      end

      def read_file(filepath)
        return nil unless File.exist?(filepath)

        File.open(filepath, 'rb') { |file| file.read }
      end

      def save_file(filepath, content)
        File.open(filepath, 'wb') { |file| file.write(content) }
        true
      end

      def cache_filename(file_key)
        Digest::SHA256.hexdigest(file_key) + '.txt'
      end

      def calculate_hash(filepath)
        Digest::SHA256.hexdigest(read_file(filepath))
      end
    end
  end
end

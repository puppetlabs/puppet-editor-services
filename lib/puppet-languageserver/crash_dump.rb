module PuppetLanguageServer
  module CrashDump
    def self.default_crash_file
      File.join(Dir.tmpdir, 'puppet_language_server_crash.txt')
    end

    def self.write_crash_file(err, filename = nil, additional = {})
      # Create the crash text

      puppet_version         = Puppet.version rescue 'Unknown' # rubocop:disable Lint/RescueWithoutErrorClass, Style/RescueModifier
      facter_version         = Facter.version rescue 'Unknown' # rubocop:disable Lint/RescueWithoutErrorClass, Style/RescueModifier
      languageserver_version = PuppetLanguageServer.version rescue 'Unknown' # rubocop:disable Lint/RescueWithoutErrorClass, Style/RescueModifier

      # rubocop:disable Layout/IndentHeredoc, Style/FormatStringToken
      crashtext = <<-TEXT
Puppet Language Server Crash File
-=--=--=--=--=--=--=--=--=--=--=-
#{DateTime.now.strftime('%a %b %e %Y %H:%M:%S %Z')}
Puppet Version #{puppet_version}
Facter Version #{facter_version}
Ruby Version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}
Language Server Version #{languageserver_version}

Error: #{err}

Backtrace
---------
#{err.backtrace.join("\n")}

TEXT
      # rubocop:enable Layout/IndentHeredoc, Style/FormatStringToken

      # Append the documents in the cache
      PuppetLanguageServer::DocumentStore.document_uris.each do |uri|
        crashtext += "Document - #{uri}\n---\n#{PuppetLanguageServer::DocumentStore.document(uri)}\n\n"
      end
      # Append additional objects from the crash
      additional.each do |k, v|
        crashtext += "#{k}\n---\n#{v}\n\n"
      end

      crash_file = filename.nil? ? default_crash_file : filename
      File.open(crash_file, 'wb') { |file| file.write(crashtext) }
    rescue # rubocop:disable Style/RescueStandardError, Lint/HandleExceptions
      # Swallow all errors.  Errors in the error handler should not
      # terminate the application
    end

    nil
  end
end

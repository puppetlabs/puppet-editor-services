module PuppetLanguageServer
  module Puppetfile
    module ValidationProvider
      def self.max_line_length
        # TODO: ... need to figure out the actual line length
        1000
      end

      def self.validate(content, _workspace, _max_problems = 100)
        result = []
        # TODO: Need to implement max_problems
        _problems = 0

        # Attempt to parse the file
        puppetfile = nil
        begin
          puppetfile = PuppetLanguageServer::Puppetfile::R10K::Puppetfile.new
          puppetfile.load!(content)
        rescue StandardError, SyntaxError, LoadError => detail
          # Find the originating error from within the puppetfile
          loc = detail.backtrace_locations
                      .select { |item| item.absolute_path == PuppetLanguageServer::Puppetfile::R10K::PUPPETFILE_MONIKER }
                      .first
          start_line_number = loc.nil? ? 0 : loc.lineno - 1 # Line numbers from ruby are base 1
          end_line_number = loc.nil? ? content.lines.count - 1 : loc.lineno - 1 # Line numbers from ruby are base 1
          # Note - Ruby doesn't give a character position so just highlight the entire line
          result << LanguageServer::Diagnostic.create('severity' => LanguageServer::DIAGNOSTICSEVERITY_ERROR,
                                                      'fromline' => start_line_number,
                                                      'toline'   => end_line_number,
                                                      'fromchar' => 0,
                                                      'tochar'   => max_line_length,
                                                      'source'   => 'Puppet',
                                                      'message'  => detail.to_s)

          puppetfile = nil
        end
        return result if puppetfile.nil?

        result
      end
    end
  end
end

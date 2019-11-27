# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/parser/errors'
require 'puppetfile-resolver/puppetfile/document'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval/dsl'

module PuppetfileResolver
  module Puppetfile
    module Parser
      # Parses a Puppetfile using the instance_eval method from R10K
      module R10KEval
        PUPPETFILE_MONIKER ||= 'Puppetfile'

        def self.parse(puppetfile_contents)
          document = ::PuppetfileResolver::Puppetfile::Document.new(puppetfile_contents)

          puppetfile_dsl = DSL.new(document)
          begin
            puppetfile_dsl.instance_eval(puppetfile_contents, PUPPETFILE_MONIKER)
          rescue StandardError, LoadError => e
            # Find the originating error from within the puppetfile
            loc = e.backtrace_locations
                   .select { |item| item.absolute_path == PUPPETFILE_MONIKER }
                   .first
            start_line_number = loc.nil? ? 0 : loc.lineno - 1 # Line numbers from ruby are base 1
            end_line_number = loc.nil? ? puppetfile_contents.lines.count - 1 : loc.lineno - 1 # Line numbers from ruby are base 1
            # Note - Ruby doesn't give a character position so just highlight the entire line

            err = PuppetfileResolver::Puppetfile::Parser::ParserError.new(e.to_s)
            err.location = PuppetfileResolver::Puppetfile::DocumentLocation.new.tap do |doc_loc|
              doc_loc.start_line = start_line_number
              doc_loc.end_line = end_line_number
            end
            raise err, e.backtrace
          rescue SyntaxError => e
            # Syntax Errrors are special as they don't appear in the backtrace :-(
            # Sytnax Errors are _really_ horrible as they don't give you the line or character position
            # as methods on the error. Instead we have to use janky regexes to get the information
            matches = /^#{PUPPETFILE_MONIKER}:(\d+):/.match(e.message)
            line_num = matches.nil? ? 0 : matches[1].to_i - 1 # Line numbers from ruby are base 1
            # If we get a string that can't be cast to integer properly to_i returns 0, which we then take 1 from
            # which results in a negative number. As a simple precaution, anything that's negative, just assume line zero
            line_num = 0 if line_num < 0

            err = PuppetfileResolver::Puppetfile::Parser::ParserError.new(e.to_s)
            err.location = PuppetfileResolver::Puppetfile::DocumentLocation.new.tap do |doc_loc|
              doc_loc.start_line = line_num
              doc_loc.end_line = line_num
              # We can't get character position reliably
            end
            raise err, e.backtrace
          end

          document
        end
      end
    end
  end
end

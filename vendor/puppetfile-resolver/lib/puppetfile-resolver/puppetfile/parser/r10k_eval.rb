# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile'
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

          # Post process magic comments
          post_process_flags!(document)

          # Freeze the flags so they can't be modified
          document.modules.each { |mod| mod.resolver_flags.freeze }

          document
        end

        # Parses a Puppetfile and applies the "magic comments"
        def self.post_process_flags!(document)
          flag_ranges = {}
          document.content.lines.each_with_index do |line, index|
            if (matches = line.match(%r{^\s*# resolver:disable ([A-Za-z\/,]+)(?:\s|$)}))
              flags_from_line(matches[1]).each do |flag|
                # Start a flag range if there isn't already one going
                next unless flag_ranges[flag].nil?
                flag_ranges[flag] = index
              end
            elsif (matches = line.match(%r{# resolver:disable ([A-Za-z\/,]+)(?:\s|$)}))
              flags_from_line(matches[1]).each do |flag|
                # Assert the flag if we're not already within a range
                next unless flag_ranges[flag].nil?
                assert_resolver_flag(document, flag, index, index)
              end
            elsif (matches = line.match(%r{^\s*# resolver:enable ([A-Za-z\/,]+)(?:\s|$)}))
              flags_from_line(matches[1]).each do |flag|
                # End a flag range if there isn't already one going
                next if flag_ranges[flag].nil?
                assert_resolver_flag(document, flag, flag_ranges[flag], index)
                flag_ranges.delete(flag)
              end
            end
          end

          return if flag_ranges.empty?
          # Any remaining flag ranges will be at the document end
          end_line = document.content.lines.count
          flag_ranges.each do |flag, start_line|
            assert_resolver_flag(document, flag, start_line, end_line)
          end
        end
        private_class_method :post_process_flags!

        # Extracts the flags from the text based definitions
        # @return [Array[Symbol]]
        def self.flags_from_line(line)
          line.split(',').map do |flag_name|
            case flag_name.downcase
            when 'dependency/puppet'
              PuppetfileResolver::Puppetfile::DISABLE_PUPPET_DEPENDENCY_FLAG
            when 'dependency/all'
              PuppetfileResolver::Puppetfile::DISABLE_ALL_DEPENDENCIES_FLAG
            when 'validation/latestversion'
              PuppetfileResolver::Puppetfile::DISABLE_LATEST_VALIDATION_FLAG
            else # rubocop:disable Style/EmptyElse We will be adding something here later
              # TODO: Should we log a warning/info here?
              nil
            end
          end.compact
        end
        private_class_method :flags_from_line

        # Sets the specified flag on modules which are between from_line to to_line
        def self.assert_resolver_flag(document, flag, from_line, to_line)
          document.modules.each do |mod|
            # If we don't know where the module is (?) then ignore it
            next if mod.location.start_line.nil? || mod.location.end_line.nil?

            # If the module doesn't span the range we're looking for (from_line --> to_line) ignore it
            next unless mod.location.start_line >= from_line && mod.location.start_line <= to_line ||
                        mod.location.end_line >= from_line && mod.location.end_line <= to_line
            mod.resolver_flags << flag unless mod.resolver_flags.include?(flag)
          end
          nil
        end
        private_class_method :assert_resolver_flag
      end
    end
  end
end

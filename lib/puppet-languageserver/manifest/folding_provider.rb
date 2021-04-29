# frozen_string_literal: true

require 'puppet-languageserver/puppet_lexer_helper'
require 'lsp/lsp'

module PuppetLanguageServer
  module Manifest
    class FoldingProvider
      class << self
        def instance
          @instance ||= new
        end

        def supported?
          # Folding is only supported on Puppet 6.3.0 and above
          # Requires - https://github.com/puppetlabs/puppet/commit/6d375ab4d735779031d49ab8631bd9d161a9c3e3
          @supported ||= Gem::Version.new(Puppet.version) >= Gem::Version.new('6.3.0')
        end
      end

      REGION_NONE = nil
      REGION_COMMENT = 'comment'
      REGION_REGION = 'region'

      def start_region?(text)
        !(text =~ %r{^#\s*region\b}).nil?
      end

      def end_region?(text)
        !(text =~ %r{^#\s*endregion\b}).nil?
      end

      def folding_ranges(tokens, show_last_line = false)
        return nil unless self.class.supported?
        ranges = {}

        brace_stack = []
        brack_stack = []
        comment_stack = []

        index = 0
        until index > tokens.length - 1
          case tokens[index][0]
          # Find comments
          when :TOKEN_COMMENT
            if block_comment?(index, tokens)
              comment = tokens[index][1].locator.extract_text(tokens[index][1].offset, tokens[index][1].length)
              if start_region?(comment) # rubocop:disable Metrics/BlockNesting
                comment_stack.push(tokens[index][1])
              elsif end_region?(comment) && !comment_stack.empty? # rubocop:disable Metrics/BlockNesting
                add_range!(create_range_span_tokens(comment_stack.pop, tokens[index][1], REGION_REGION), ranges)
              else
                index = process_block_comment!(index, tokens, ranges)
              end
            end

          # Find old style comments /* -> */
          when :TOKEN_MLCOMMENT
            add_range!(create_range_whole_token(tokens[index][1], REGION_COMMENT), ranges)

          # Find matching braces { -> } and select brace ?{ -> }
          when :LBRACE, :SELBRACE
            brace_stack.push(tokens[index][1])
          when :RBRACE
            add_range!(create_range_span_tokens(brace_stack.pop, tokens[index][1], REGION_NONE), ranges) unless brace_stack.empty?

          # Find matching braces [ -> ], list and index
          when :LISTSTART, :LBRACK
            brack_stack.push(tokens[index][1])
          when :RBRACK
            add_range!(create_range_span_tokens(brack_stack.pop, tokens[index][1], REGION_NONE), ranges) unless brack_stack.empty?

          # Find matching Heredoc and heredoc sublocations
          when :HEREDOC
            # Need to check if the next token is :SUBLOCATE
            if index < tokens.length - 2 && tokens[index + 1][0] == :SUBLOCATE # rubocop:disable Style/IfUnlessModifier
              add_range!(create_range_heredoc(tokens[index][1], tokens[index + 1][1], REGION_NONE), ranges)
            end
          end

          index += 1
        end

        # If we are showing the last line then decrement the EndLine by one, if possible
        if show_last_line
          ranges.values.each do |range|
            range.endLine = [range.startLine, range.endLine - 1].max
            range.endCharacter = 0 # We don't know where the previous line actually ends so set it to zero
          end
        end

        ranges.values
      end

      private

      # region Internal Helper methods to call locator methods on Locators or SubLocators
      def line_for_offset(token, offset = nil)
        locator_method_with_offset(token, :line_for_offset, offset || token.offset)
      end

      def pos_on_line(token, offset = nil)
        locator_method_with_offset(token, :pos_on_line, offset || token.offset)
      end

      def locator_method_with_offset(token, method_name, offset)
        if token.locator.is_a?(Puppet::Pops::Parser::Locator::SubLocator)
          global_offset, = token.locator.to_global(offset, token.length)
          token.locator.locator.send(method_name, global_offset)
        else
          token.locator.send(method_name, offset)
        end
      end

      def extract_text(token)
        if token.locator.is_a?(Puppet::Pops::Parser::Locator::SubLocator)
          global_offset, global_length = token.locator.to_global(token.offset, token.length)
          token.locator.locator.extract_text(global_offset, global_length)
        else
          token.locator.extract_text(token.offset, token.length)
        end
      end
      # endregion

      # Return nil if not valid range
      def create_range_span_tokens(start_token, end_token, kind)
        start_line = line_for_offset(start_token) - 1
        end_line = line_for_offset(end_token) - 1
        return nil if start_line == end_line
        LSP::FoldingRange.new({
                                'startLine'      => start_line,
                                'startCharacter' => pos_on_line(start_token) - 1,
                                'endLine'        => end_line,
                                'endCharacter'   => pos_on_line(end_token, end_token.offset + end_token.length) - 1,
                                'kind'           => kind
                              })
      end

      # Return nil if not valid range
      def create_range_whole_token(token, kind)
        start_line = line_for_offset(token) - 1
        end_line = line_for_offset(token, token.offset + token.length) - 1
        return nil if start_line == end_line
        LSP::FoldingRange.new({
                                'startLine'      => start_line,
                                'startCharacter' => pos_on_line(token) - 1,
                                'endLine'        => end_line,
                                'endCharacter'   => pos_on_line(token, token.offset + token.length) - 1,
                                'kind'           => kind
                              })
      end

      # Return nil if not valid range
      def create_range_heredoc(heredoc_token, subloc_token, kind)
        start_line = line_for_offset(heredoc_token) - 1
        # The lexer does not output the end heredoc_token. Instead we
        # use the heredoc sublocator endline and add one
        end_line = line_for_offset(heredoc_token, heredoc_token.offset + heredoc_token.length + subloc_token.length)
        return nil if start_line == end_line
        LSP::FoldingRange.new({
                                'startLine'      => start_line,
                                'startCharacter' => pos_on_line(heredoc_token) - 1,
                                'endLine'        => end_line,
                                # We don't know where the end token for the Heredoc is, so just assume it's at the start of the line
                                'endCharacter'   => 0,
                                'kind'           => kind
                              })
      end

      # Adds a FoldingReference to the list and enforces ordering rules e.g. Only one fold per start line
      def add_range!(range, ranges)
        # Make sure the arguments are correct
        return nil if range.nil? || ranges.nil?

        # Ignore the range if there is an existing one which is bigger
        return nil unless ranges[range.startLine].nil? || ranges[range.startLine].endLine < range.endLine
        ranges[range.startLine] = range
        nil
      end

      # Returns new index position
      def process_block_comment!(index, tokens, ranges)
        start_index = index
        line_num = line_for_offset(tokens[index][1])
        while index < tokens.length - 2
          break unless tokens[index + 1][0] == :TOKEN_COMMENT
          next_line = line_for_offset(tokens[index + 1][1])
          # Tokens must be on contiguous lines
          break unless next_line == line_num + 1
          # Must not be a region comment
          comment = extract_text(tokens[index + 1][1])
          break if start_region?(comment) || end_region?(comment)
          # It's a block comment
          line_num = next_line
          index += 1
        end

        return index if start_index == index

        add_range!(create_range_span_tokens(tokens[start_index][1], tokens[index][1], REGION_COMMENT), ranges)
        index
      end

      def block_comment?(index, tokens)
        # Has to be a comment token
        return false unless tokens[index][0] == :TOKEN_COMMENT
        # If it's the first token then it has to be at the start of a line
        return true if index.zero?
        # It has to be the first token on this line
        this_token_line = line_for_offset(tokens[index][1])
        prev_token_line = line_for_offset(tokens[index - 1][1])

        this_token_line != prev_token_line
      end
    end
  end
end

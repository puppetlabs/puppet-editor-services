# frozen_string_literal: true

require 'puppet-lint'

module PuppetLanguageServer
  module Manifest
    class FormatOnTypeProvider
      class << self
        def instance
          @instance ||= new
        end
      end

      def format(content, line, char, trigger_character, formatting_options)
        result = []
        # Abort if the user has pressed something other than `>`
        return result unless trigger_character == '>'
        # Abort if the formatting is tab based. Can't do that yet
        return result unless formatting_options['insertSpaces'] == true
        # Abort if content is too big
        return result if content.length > 4096

        lexer = PuppetLint::Lexer.new
        tokens = lexer.tokenise(content)

        # Find where in the manifest the cursor is
        cursor_token = find_token_by_location(tokens, line, char)
        return result if cursor_token.nil?
        # The cursor should be at the end of a hashrocket, otherwise exit
        return result unless cursor_token.type == :FARROW

        # Find the start of the hash (or semicolon for multi-resource definitions) with respect to the cursor
        start_brace = cursor_token.prev_token_of(%i[LBRACE SEMIC], skip_blocks: true)
        # Find the end of the hash (or semicolon for multi-resource definitions) with respect to the cursor
        end_brace = cursor_token.next_token_of(%i[RBRACE SEMIC], skip_blocks: true)

        # The line count between the start and end brace needs to be at least 2 lines. Otherwise there's nothing to align to
        return result if end_brace.nil? || start_brace.nil? || end_brace.line - start_brace.line <= 2

        # Find all hashrockets '=>' between the hash braces, ignoring nested hashes
        farrows = []
        farrow_token = start_brace
        lines = []
        loop do
          farrow_token = farrow_token.next_token_of(:FARROW, skip_blocks: true)
          # if there are no more hashrockets, or we've gone past the end_brace, we can exit the loop
          break if farrow_token.nil? || farrow_token.line > end_brace.line
          # if there's a hashrocket AFTER the closing brace (why?) then we can also exit the loop
          break if farrow_token.line == end_brace.line && farrow_token.character > end_brace.character
          # Check for multiple hashrockets on the same line. If we find some, then we can't do any automated indentation
          return result if lines.include?(farrow_token.line)
          lines << farrow_token.line
          farrows << { token: farrow_token }
        end

        # Now we have a list of farrows, time for figure out the indentation marks
        farrows.each do |item|
          item.merge!(calculate_indentation_info(item[:token]))
        end

        # Now we have the list of indentations we can find the biggest
        max_indent = -1
        farrows.each do |info|
          max_indent = info[:indent] if info[:indent] > max_indent
        end
        # No valid indentations found
        return result if max_indent == -1

        # Now we have the indent size, generate all of the required TextEdits
        farrows.each do |info|
          # Ignore invalid hashrockets
          next if info[:indent] == -1
          end_name_token = info[:name_token].column + info[:name_token].to_manifest.length
          begin_farrow_token = info[:token].column
          new_whitespace = max_indent - end_name_token
          # If the whitespace is already what we want, then ignore it.
          next if begin_farrow_token - end_name_token == new_whitespace

          # Create the TextEdit
          result << LSP::TextEdit.new.from_h!(
            'newText' => ' ' * new_whitespace,
            'range'   => LSP.create_range(info[:token].line - 1, end_name_token - 1, info[:token].line - 1, begin_farrow_token - 1)
          )
        end
        result
      end

      private

      VALID_TOKEN_TYPES = %i[NAME STRING SSTRING].freeze

      def find_token_by_location(tokens, line, character)
        return nil if tokens.empty?
        # Puppet Lint uses base 1, but LSP is base 0, so adjust accordingly
        cursor_line = line + 1
        cursor_column = character + 1
        idx = -1
        while idx < tokens.count
          idx += 1
          # if the token is on previous lines keep looking...
          next if tokens[idx].line < cursor_line
          # return nil if we skipped over the line we need
          return nil if tokens[idx].line > cursor_line
          # return nil if we skipped over the character position we need
          return nil if tokens[idx].column > cursor_column
          # return the token if it starts on the cursor column we are interested in
          return tokens[idx] if tokens[idx].column == cursor_column
          end_column = tokens[idx].column + tokens[idx].to_manifest.length
          # return the token it the cursor column is within the token string
          return tokens[idx] if cursor_column <= end_column
          # otherwise, keep on searching
        end
        nil
      end

      def calculate_indentation_info(farrow_token)
        result = { indent: -1 }
        # This is not a valid hashrocket if there's no previous tokens
        return result if farrow_token.prev_token.nil?
        if VALID_TOKEN_TYPES.include?(farrow_token.prev_token.type)
          # Someone forgot the whitespace! e.g. ensure=>
          result[:indent] = farrow_token.column + 1
          result[:name_token] = farrow_token.prev_token
          return result
        end
        if farrow_token.prev_token.type == :WHITESPACE
          # If the whitespace has no previous token (which shouldn't happen) or the thing before the whitespace is not a property name this it not a valid hashrocket
          return result if farrow_token.prev_token.prev_token.nil?
          return result unless VALID_TOKEN_TYPES.include?(farrow_token.prev_token.prev_token.type)
          result[:name_token] = farrow_token.prev_token.prev_token
          result[:indent] = farrow_token.prev_token.column + 1 # The indent is the whitespace column + 1
        end
        result
      end
    end
  end
end

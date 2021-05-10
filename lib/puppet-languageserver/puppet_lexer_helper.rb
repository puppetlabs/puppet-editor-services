# frozen_string_literal: true

module Puppet
  module Pops
    module Parser
      # This Lexer adds code to create comment tokens.
      # The default lexer just throws them out
      # Ref - https://github.com/puppetlabs/puppet-specifications/blob/master/language/lexical_structure.md#comments
      class Lexer2WithComments < Puppet::Pops::Parser::Lexer2
        # The PATTERN_COMMENT in lexer2 also consumes the trailing \r in the token and
        # we don't want that.
        PATTERN_COMMENT_NO_WS = %r{#[^\r\n]*}.freeze

        TOKEN_COMMENT = [:COMMENT, '#', 1].freeze
        TOKEN_MLCOMMENT = [:MLCOMMENT, nil, 0].freeze

        def initialize
          super

          # Remove the selector for line comments so we can add our own
          @new_selector = @selector.reject { |k, _v| k == '#' }

          # Add code to scan line comments
          @new_selector['#'] = lambda {
            scn = @scanner
            before = scn.pos
            value = scn.scan(PATTERN_COMMENT_NO_WS)

            if value
              emit_completed([:TOKEN_COMMENT, value[1..-1].freeze, scn.pos - before], before)
            else
              # It's probably not possible to EVER get here ... but just incase
              emit(TOKEN_COMMENT, before)
            end
          }.freeze

          # Add code to scan multi-line comments
          old_lambda = @new_selector['/']
          @new_selector['/'] = lambda {
            scn = @scanner
            la = scn.peek(2)
            if la[1] == '*'
              before = scn.pos
              value = scn.scan(PATTERN_MLCOMMENT)
              return emit_completed([:TOKEN_MLCOMMENT, value[2..-3].freeze, scn.pos - before], before) if value
            end
            old_lambda.call
          }.freeze
          @new_selector.freeze
          @selector = @new_selector
        end
      end
    end
  end
end

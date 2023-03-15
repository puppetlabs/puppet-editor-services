# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This cop checks for blocks without a body.
      # Such empty blocks are typically an oversight or we should provide a comment
      # be clearer what we're aiming for.
      #
      # Empty lambdas are ignored by default.
      #
      # @example
      #   # bad
      #   items.each { |item| }
      #
      #   # good
      #   items.each { |item| puts item }
      #
      # @example AllowComments: true (default)
      #   # good
      #   items.each do |item|
      #     # TODO: implement later (inner comment)
      #   end
      #
      #   items.each { |item| } # TODO: implement later (inline comment)
      #
      # @example AllowComments: false
      #   # bad
      #   items.each do |item|
      #     # TODO: implement later (inner comment)
      #   end
      #
      #   items.each { |item| } # TODO: implement later (inline comment)
      #
      # @example AllowEmptyLambdas: true (default)
      #   # good
      #   allow(subject).to receive(:callable).and_return(-> {})
      #
      #   placeholder = lambda do
      #   end
      #   (callable || placeholder).call
      #
      # @example AllowEmptyLambdas: false
      #   # bad
      #   allow(subject).to receive(:callable).and_return(-> {})
      #
      #   placeholder = lambda do
      #   end
      #   (callable || placeholder).call
      #
      class EmptyBlock < Base
        MSG = 'Empty block detected.'

        def on_block(node)
          return if node.body
          return if allow_empty_lambdas? && node.lambda?
          return if cop_config['AllowComments'] && allow_comment?(node)

          add_offense(node)
        end

        private

        def allow_comment?(node)
          return false unless processed_source.contains_comment?(node.source_range)

          line_comment = processed_source.comment_at_line(node.source_range.line)
          !line_comment || !comment_disables_cop?(line_comment.loc.expression.source)
        end

        def allow_empty_lambdas?
          cop_config['AllowEmptyLambdas']
        end

        def comment_disables_cop?(comment)
          regexp_pattern = "# rubocop : (disable|todo) ([^,],)* (all|#{cop_name})"
          Regexp.new(regexp_pattern.gsub(' ', '\s*')).match?(comment)
        end
      end
    end
  end
end

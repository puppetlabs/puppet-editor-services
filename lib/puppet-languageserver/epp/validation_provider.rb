# frozen_string_literal: true

module PuppetLanguageServer
  module Epp
    module ValidationProvider
      def self.validate(content, _max_problems = 100)
        result = []
        # TODO: Need to implement max_problems
        _problems = 0

        begin
          parser = Puppet::Pops::Parser::EvaluatingParser::EvaluatingEppParser.new
          parser.parse_string(content, nil)
        rescue StandardError => e
          # Sometimes the error is in the cause not the root object itself
          e = e.cause if !e.respond_to?(:line) && e.respond_to?(:cause)
          ex_line = e.respond_to?(:line) && !e.line.nil? ? e.line - 1 : nil # Line numbers from puppet exceptions are base 1
          ex_pos = e.respond_to?(:pos) && !e.pos.nil? ? e.pos : nil # Pos numbers from puppet are base 1

          message = e.respond_to?(:message) ? e.message : nil
          message = e.basic_message if message.nil? && e.respond_to?(:basic_message)

          unless ex_line.nil? || ex_pos.nil? || message.nil?
            result << LSP::Diagnostic.new('severity' => LSP::DiagnosticSeverity::ERROR,
                                          'range'    => LSP.create_range(ex_line, ex_pos, ex_line, ex_pos + 1),
                                          'source'   => 'Puppet',
                                          'message'  => message)
          end
        end
        result
      end
    end
  end
end

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
        rescue StandardError => detail
          # Sometimes the error is in the cause not the root object itself
          detail = detail.cause if !detail.respond_to?(:line) && detail.respond_to?(:cause)
          ex_line = detail.respond_to?(:line) && !detail.line.nil? ? detail.line - 1 : nil # Line numbers from puppet exceptions are base 1
          ex_pos = detail.respond_to?(:pos) && !detail.pos.nil? ? detail.pos : nil # Pos numbers from puppet are base 1

          message = detail.respond_to?(:message) ? detail.message : nil
          message = detail.basic_message if message.nil? && detail.respond_to?(:basic_message)

          unless ex_line.nil? || ex_pos.nil? || message.nil?
            result << LanguageServer::Diagnostic.create('severity' => LanguageServer::DIAGNOSTICSEVERITY_ERROR,
                                                        'fromline' => ex_line,
                                                        'toline' => ex_line,
                                                        'fromchar' => ex_pos,
                                                        'tochar' => ex_pos + 1,
                                                        'source' => 'Puppet',
                                                        'message' => message)
          end
        end
        result
      end
    end
  end
end

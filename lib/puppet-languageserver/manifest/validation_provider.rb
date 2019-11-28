# frozen_string_literal: true

require 'puppet-lint'
module PuppetLanguageServer
  module Manifest
    module ValidationProvider
      # Similar to 'validate' this will run puppet-lint and returns
      # the manifest with any fixes applied
      #
      # Returns:
      #  [ <Int> Number of problems fixed,
      #    <String> New Content
      #  ]
      def self.fix_validate_errors(content)
        module_root = PuppetLanguageServer::DocumentStore.store_root_path
        linter_options = nil
        if module_root.nil?
          linter_options = PuppetLint::OptParser.build
        else
          Dir.chdir(module_root.to_s) { linter_options = PuppetLint::OptParser.build }
        end
        linter_options.parse!(['--fix'])

        linter = PuppetLint::Checks.new
        linter.load_data(nil, content)

        problems = linter.run(nil, content)
        problems_fixed = problems.nil? ? 0 : problems.count { |item| item[:kind] == :fixed }

        [problems_fixed, linter.manifest]
      end

      def self.validate(content, options = {})
        options = {
          :max_problems => 100,
          :tasks_mode   => false
        }.merge(options)

        result = []
        # TODO: Need to implement max_problems
        problems = 0

        module_root = PuppetLanguageServer::DocumentStore.store_root_path
        linter_options = nil
        if module_root.nil?
          linter_options = PuppetLint::OptParser.build
        else
          Dir.chdir(module_root.to_s) { linter_options = PuppetLint::OptParser.build }
        end
        linter_options.parse!([])

        begin
          linter = PuppetLint::Checks.new
          linter.load_data(nil, content)

          problems = linter.run(nil, content)
          unless problems.nil?
            problems.each do |problem|
              # Syntax errors are better handled by the puppet parser, not puppet lint
              next if problem[:kind] == :error && problem[:check] == :syntax
              # Ignore linting errors what were ignored by puppet-lint
              next if problem[:kind] == :ignored

              severity = case problem[:kind]
                         when :error
                           LSP::DiagnosticSeverity::ERROR
                         when :warning
                           LSP::DiagnosticSeverity::WARNING
                         else
                           LSP::DiagnosticSeverity::HINT
                         end

              endpos = problem[:column] - 1
              endpos = problem[:column] - 1 + problem[:token].to_manifest.length unless problem[:token].nil? || problem[:token].value.nil?

              result << LSP::Diagnostic.new('severity' => severity,
                                            'code'     => problem[:check].to_s,
                                            'range'    => LSP.create_range(problem[:line] - 1, problem[:column] - 1, problem[:line] - 1, endpos),
                                            'source'   => 'Puppet',
                                            'message'  => problem[:message])
            end
          end
        # rubocop:disable Lint/SuppressedException
        rescue StandardError
          # If anything catastrophic happens we resort to puppet parsing anyway
        end
        # rubocop:enable Lint/SuppressedException

        # TODO: Should I wrap this thing in a big rescue block?
        Puppet[:code] = content
        env = Puppet.lookup(:current_environment)
        loaders = Puppet::Pops::Loaders.new(env)
        Puppet.override({ loaders: loaders }, 'For puppet parser validate') do
          begin
            validation_environment = env
            $PuppetParserMutex.synchronize do # rubocop:disable Style/GlobalVars
              begin
                original_taskmode = Puppet[:tasks] if Puppet.tasks_supported?
                Puppet[:tasks] = options[:tasks_mode] if Puppet.tasks_supported?
                validation_environment.check_for_reparse
                validation_environment.known_resource_types.clear
              ensure
                Puppet[:tasks] = original_taskmode if Puppet.tasks_supported?
              end
            end
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
        end

        result
      end
    end
  end
end

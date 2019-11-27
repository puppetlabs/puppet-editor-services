# frozen_string_literal: true

require 'lsp/lsp'

module PuppetLanguageServer
  module Puppetfile
    module ValidationProvider
      def self.max_line_length
        # TODO: ... need to figure out the actual line length
        1000
      end

      def self.validate(content, options = {})
        options = {
          :max_problems       => 100,
          :resolve_puppetfile => true,
          :module_path        => [],
          :document_uri       => '???'
        }.merge(options)

        result = []
        # TODO: Need to implement max_problems
        _problems = 0

        require 'puppetfile-resolver'
        require 'puppetfile-resolver/puppetfile/parser/r10k_eval'
        parser = PuppetfileResolver::Puppetfile::Parser::R10KEval

        # Attempt to parse the file
        puppetfile = nil
        begin
          puppetfile = parser.parse(content)
        rescue PuppetfileResolver::Puppetfile::Parser::ParserError => e
          result << LSP::Diagnostic.new(
            'severity' => LSP::DiagnosticSeverity::ERROR,
            'range'    => document_location_to_lsp_range(e.location),
            'source'   => 'Puppet',
            'message'  => e.to_s
          )
          puppetfile = nil
        end
        return result if puppetfile.nil?

        puppetfile.validation_errors.each do |validation_error|
          related_information = nil

          if validation_error.is_a?(PuppetfileResolver::Puppetfile::DocumentDuplicateModuleError)
            related_information = validation_error.duplicates.map do |dup_mod|
              {
                'location' => {
                  'uri'   => options[:document_uri],
                  'range' => document_location_to_lsp_range(dup_mod.location)
                },
                'message'  => validation_error.message
              }
            end
          end

          result << LSP::Diagnostic.new(
            'severity'           => LSP::DiagnosticSeverity::ERROR,
            'range'              => document_location_to_lsp_range(validation_error.puppet_module.location),
            'source'             => 'Puppet',
            'message'            => validation_error.message,
            'relatedInformation' => related_information
          )
        end

        return result unless options[:resolve_puppetfile] && puppetfile.valid?

        result + validate_resolution(puppetfile, options[:document_uri], resolver_cache, options[:module_path], options[:puppet_version])
      end

      def self.validate_resolution(puppetfile_document, document_uri, cache, module_path, puppet_version)
        ui = nil
        resolver = PuppetfileResolver::Resolver.new(puppetfile_document, puppet_version)
        opts = { cache: cache, ui: ui, module_paths: module_path, allow_missing_modules: true }
        begin
          resolution = resolver.resolve(opts)
        rescue PuppetfileResolver::Puppetfile::DocumentVersionConflictError,
               PuppetfileResolver::Puppetfile::DocumentCircularDependencyError => e
          return [document_error_to_diagnostic(document_uri, e)]
        rescue PuppetfileResolver::Puppetfile::DocumentResolveError => e
          return [LSP::Diagnostic.new(
            'severity' => LSP::DiagnosticSeverity::ERROR,
            'range'    => LSP.create_range(0, 0, 0, max_line_length),
            'source'   => 'Puppet',
            'message'  => e.message
          )]
        end

        resolution.validation_errors.map do |error|
          severity = case error
                     when PuppetfileResolver::Puppetfile::DocumentLatestVersionError
                       LSP::DiagnosticSeverity::INFORMATION
                     when PuppetfileResolver::Puppetfile::DocumentMissingModuleError
                       LSP::DiagnosticSeverity::HINT
                     else
                       LSP::DiagnosticSeverity::ERROR
                     end
          LSP::Diagnostic.new(
            'severity' => severity,
            'range'    => document_location_to_lsp_range(error.puppet_module.location),
            'source'   => 'Puppet',
            'message'  => error.message
          )
        end
      end

      def self.resolver_cache
        return @resolver_cache unless @resolver_cache.nil?
        require 'puppetfile-resolver/cache/base'
        # TODO: The cache should probably not cache local module information though
        # Share a cache between resolution calls to speed-up lookups
        @resolver_cache = PuppetfileResolver::Cache::Base.new(nil)
      end
      private_class_method :resolver_cache

      def self.document_error_to_diagnostic(document_uri, error)
        if error.puppetfile_modules.count.zero?
          return LSP::Diagnostic.new(
            'severity' => LSP::DiagnosticSeverity::ERROR,
            'range'    => LSP.create_range(0, 0, 0, max_line_length),
            'source'   => 'Puppet',
            'message'  => error.message
          )
        end

        related_information = error.puppetfile_modules.slice(1..-1).map do |dup_mod|
          {
            'location' => {
              'uri'   => document_uri,
              'range' => document_location_to_lsp_range(dup_mod.location)
            },
            'message'  => "Module definition for #{dup_mod.name}"
          }
        end

        LSP::Diagnostic.new(
          'severity'           => LSP::DiagnosticSeverity::ERROR,
          'range'              => document_location_to_lsp_range(error.puppetfile_modules[0].location),
          'source'             => 'Puppet',
          'message'            => error.message,
          'relatedInformation' => related_information.empty? ? nil : related_information
        )
      end
      private_class_method :document_error_to_diagnostic

      def self.document_location_to_lsp_range(location)
        start_line = location.start_line
        start_char = location.start_char.nil? ? 0 : location.start_char
        end_line = location.end_line
        end_char = location.end_char.nil? ? max_line_length : location.end_char
        LSP.create_range(start_line, start_char, end_line, end_char)
      end
      private_class_method :document_location_to_lsp_range
    end
  end
end

module PuppetLanguageServer
  module PuppetStrings
    @yard_setup = false

    DEFAULT_SEARCH_PATTERNS = %w[
      manifests/**/*.pp
      functions/**/*.pp
      types/**/*.pp
      lib/**/*.rb
    ].freeze

    def self.render(options = {})
      raise 'Puppet Strings can only be generated within a module' if options[:workspace].nil?

      raise 'Puppet Strings is not available' unless require_puppet_strings

      search_patterns = options[:search_patterns].nil? ? PuppetStrings::DEFAULT_SEARCH_PATTERNS : options[:search_patterns]
      # Munge the search patterns to the local workspace
      search_patterns = search_patterns.map { |pattern| File.join(options[:workspace], pattern) }

      unless @yard_setup
        ::PuppetStrings::Yard.setup!
        @yard_setup = true
      end

      # Format the arguments to YARD
      args = ['doc']
      args << '--debug'     if options[:debug]
      args << '--backtrace' if options[:backtrace]
      args << '-mmarkdown'

      args << '-n'
      args << '-q'
      args << '--no-stats'
      args << '--no-progress'
      args << '--no-save'

      yard_args = options[:yard_args]

      args += yard_args if yard_args
      args += search_patterns

      # Run YARD
      ::YARD::CLI::Yardoc.run(*args)
      ::PuppetStrings::Markdown.generate
    end

    def self.require_puppet_strings
      return @puppet_strings_loaded unless @puppet_strings_loaded.nil?
      begin
        require 'puppet-strings'
        require 'puppet-strings/yard'
        require 'puppet-strings/markdown'
        @puppet_strings_loaded = true
      rescue LoadError => ex
        PuppetLanguageServer.log_message(:error, "Unable to load puppet-strings gem: #{ex}")
        @puppet_strings_loaded = false
      end
      @puppet_strings_loaded
    end
    private_class_method :require_puppet_strings
  end
end

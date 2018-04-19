module PuppetEditorServices
  def self.log_message(severity, message)
    return if @logger.nil?

    case severity
    when :debug
      @logger.debug(message)
    when :info
      @logger.info(message)
    when :warn
      @logger.info(message)
    when :error
      @logger.error(message)
    when :fatal
      @logger.fatal(message)
    else
      @logger.unknown(message)
    end
    @log_file.fsync unless @log_file.nil?
  end

  def self.init_logging(options)
    @log_file = nil
    if options[:debug].nil?
      @logger = nil
    elsif (options[:debug].casecmp 'stdout').zero?
      @logger = Logger.new($stdout)
    elsif !options[:debug].to_s.empty?
      # Log to file
      begin
        @log_file = File.open(options[:debug], 'w')
      rescue Errno::ENOENT => e
        # We can't open the log file and we can't log to STDOUT if we're in STDIO mode
        # So log the error to STDERR and disable logging
        $stderr.puts "Error opening log file #{options[:debug]} : #{e}" # rubocop:disable Style/StderrPuts
        @log_file = nil
        return
      end
      @log_file.sync = true
      @logger = Logger.new(@log_file)
    end
  end
end

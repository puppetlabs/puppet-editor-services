# frozen_string_literal: true

module PuppetDebugServer
  module DebugSession
    # Manages storing and validating breakpoints for the Debug Session.
    class BreakPoints
      # @param debug_session [PuppetDebugServer::PuppetDebugSession] The debug session to manage the flow for.
      def initialize(debug_session)
        @debug_session = debug_session

        @breakpoint_mutex = Mutex.new
        @source_breakpoints = {}
        @function_breakpoints = []
      end

      # Takes the arguments for the setBreakpoints request and then validates that the breakpoints requested
      # are valid and exist.
      #
      # @todo Do we care about Breakpoint.Id? That seems to be only required for activating/deactivating breakpoints dynamically.
      # @param arguments [DSP::SetBreakpointsArguments]
      # @return [Array<DSP::Breakpoint>] All of the breakpoints, in the same order as arguments, with validation set correctly.
      def process_set_breakpoints_request!(arguments)
        file_path = File.expand_path(arguments.source.path) # Rub-ify the filepath. Important on Windows platforms.
        file_contents = {}

        if File.exist?(file_path)
          # Open the file and extact the lines we need
          line_list = arguments.breakpoints.map(&:line) # These are 1-based line numbers

          begin
            # TODO: This could be slow on big files....
            IO.foreach(file_path, :mode => 'rb', :encoding => 'UTF-8').each_with_index do |item, index|
              # index here zero-based whereas we want one-based indexing
              file_contents[index + 1] = item if line_list.include?(index + 1)
            end
          rescue StandardError => e
            PuppetDebugServer.log_message(:error, "Error reading file #{arguments.source.path} for source breakpoints: #{e}")
          end
        else
          PuppetDebugServer.log_message(:debug, "Unable to set source breakpoints for non-existant file #{arguments.source.path}")
        end

        # Create the initial list of breakpoint responses
        break_points = arguments.breakpoints.map do
          DSP::Breakpoint.new.from_h!(
            'verified' => false,
            'source'   => arguments.source.to_h
          )
        end

        # The internal list of break points only cares about valid breakpoints
        @breakpoint_mutex.synchronize { @source_breakpoints[canonical_file_path(file_path)] = [] }
        # Verify that each breakpoints is valid
        arguments.breakpoints.each_with_index do |sbp, bp_index|
          line_text = file_contents[sbp.line]
          bp = break_points[bp_index]

          if line_text.nil?
            bp.message = 'Line does not exist'
            next
          end

          bp.line = sbp.line

          # Strip whitespace
          line_text.strip!
          # Strip block comments i.e. `  # something`
          line_text = line_text.partition('#')[0]

          if line_text.empty?
            bp.message = 'Line is blank'
          else
            bp.verified = true
            @breakpoint_mutex.synchronize { @source_breakpoints[canonical_file_path(file_path)] << bp }
          end
        end

        break_points
      end

      # Takes the arguments for the setFunctionBreakpoints request and then validates that the breakpoints requested are valid.
      #
      # @todo Do we care about Breakpoint.Id? That seems to be only required for activating/deactivating breakpoints dynamically.
      # @param arguments [DSP::SetFunctionBreakpointsArguments]
      # @return [Array<DSP::Breakpoint>] All of the breakpoints, in the same order as arguments, with validation set correctly.
      def process_set_function_breakpoints_request!(arguments)
        # Update this internal list of active breakpoints
        @breakpoint_mutex.synchronize do
          @function_breakpoints = arguments.breakpoints
        end

        # All Function breakpoints are considered valid
        arguments.breakpoints.map do
          DSP::Breakpoint.new.from_h!(
            'verified' => true
          )
        end
      end

      # Returns all of the line breakpoints for a given file.
      #
      # @param file_path [String] Absolute path to the file.
      # @return [Array<Integer>] All of the line breakpoints. Returns empty array if there no breakpoints.
      def line_breakpoints(file_path)
        return [] if @source_breakpoints[canonical_file_path(file_path)].nil?
        @source_breakpoints[canonical_file_path(file_path)].map(&:line)
      end

      # Returns all of the function names that should break on.
      #
      # @return [Array<String>] All of the function names that the debugger should break on
      def function_breakpoint_names
        result = @function_breakpoints.map(&:name)
        # Also add the debug::break function which mimics puppet-debug behaviour
        # https://github.com/nwops/puppet-debug#usage
        result << 'debug::break'
      end

      private

      # Returns unique, canonical name for a file path, regardless of Operating System.
      #
      # @param file_path [String] The path to canonicalise.
      # @return [String] All of the function names that the debugger should break on.
      # @private
      def canonical_file_path(file_path)
        # This could be a little dangerous. The paths that come from the editor are URIs, and may or may not always
        # represent their actual filename on disk e.g. case-insensitive file systems. So a quick and dirty way to
        # reconcile this is just to always use lowercase file paths. While this works ok on Windows (NTFS or FAT)
        # other operating systems, could, in theory have two manifests being debugged that only differ by case. This
        # is not recommend as it breaks cross platform editing, but it's still possible
        file_path.downcase
      end
    end
  end
end

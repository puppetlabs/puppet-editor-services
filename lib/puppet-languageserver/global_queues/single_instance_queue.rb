# frozen_string_literal: true

module PuppetLanguageServer
  module GlobalQueues
    class SingleInstanceQueueJob
      # Unique key for the job. The SingleInstanceQueue uses the key
      # to ensure that only a single instance is in the queue
      attr_reader :key

      def initialize(key)
        @key = key
      end
    end

    # Base class for enqueing and running queued jobs asynchronously
    # When adding a job, it will remove any other for the same
    # key in the queue, so that only the latest job needs to be processed.
    class SingleInstanceQueue
      def initialize
        @queue = []
        @queue_mutex = Mutex.new
        @queue_threads_mutex = Mutex.new
        @queue_threads = []
      end

      # Default is one thread to process the queue
      def max_queue_threads
        1
      end

      # The ruby Job class that this queue operates on
      # Should be inherited from SingleInstanceQueueJob
      # @api asbtract
      def job_class
        SingleInstanceQueueJob
      end

      def new_job(*args)
        job_class.new(*args)
      end

      # Helpful method to create, then enqueue a job
      def enqueue(*args)
        enqueue_job(new_job(*args))
      end

      # Enqueue a job
      def enqueue_job(job_object)
        raise "Invalid job object for #{self.class}. Got #{job_object.class} but expected #{job_class}" unless job_object.is_a?(job_class)

        @queue_mutex.synchronize do
          @queue.reject! { |queue_item| queue_item.key == job_object.key }
          @queue << job_object
        end

        @queue_threads_mutex.synchronize do
          # Clear up any done threads
          @queue_threads.reject! { |thr| thr.nil? || !thr.alive? }
          # Append a new thread if we have space
          if @queue_threads.count < max_queue_threads
            @queue_threads << Thread.new do
              begin
                thread_worker
              rescue => e # rubocop:disable Style/RescueStandardError
                PuppetLanguageServer.log_message(:error, "Error in #{self.class} Thread: #{e}")
                raise
              end
            end
          end
        end
        nil
      end

      # Helpful method to create, then enqueue a job
      def execute(*args)
        execute_job(new_job(*args))
      end

      # Synchronously executes the same work as an enqueued item. Does not consume a queue thread
      # The thread worker calls this method when processing enqueued items
      # @abstract
      def execute_job(job_object)
        raise "Invalid job object for #{self.class}. Got #{job_object.class} but expected #{job_class}" unless job_object.is_a?(job_class)
      end

      # Wait for the queue to become empty
      def drain_queue
        @queue_threads.each do |item|
          item.join unless item.nil? || !item.alive?
        end
        nil
      end

      # Testing helper resets the queue and prepopulates it with
      # a known arbitrary configuration.
      # ONLY USE THIS FOR TESTING!
      def reset_queue(initial_state = [])
        @queue_mutex.synchronize do
          @queue = initial_state
        end
      end

      private

      # Thread worker which processes all jobs in the queue and calls the sidecar for each action
      def thread_worker
        work_item = nil
        loop do
          @queue_mutex.synchronize do
            return if @queue.empty?

            work_item = @queue.shift
          end
          return if work_item.nil?

          # Perform action
          begin
            # When running async (i.e. from a thread swallow any output)
            _result = execute_job(work_item)
          rescue StandardError => e
            PuppetLanguageServer.log_message(:error, "#{self.class} Thread: Error running job #{work_item.key}. #{e}\n#{e.backtrace}")
            nil
          end
        end
      end
    end
  end
end

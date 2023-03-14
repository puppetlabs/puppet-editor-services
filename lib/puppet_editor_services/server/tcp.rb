# frozen_string_literal: true

require 'socket'
require 'openssl'

# frozen_string_literal: true

require 'puppet_editor_services/logging'
require 'puppet_editor_services/server/base'
require 'puppet_editor_services/connection/tcp'
require 'puppet_editor_services/protocol/base'

# Based on code from
# http://stackoverflow.com/questions/29858113/unable-to-make-socket-accept-non-blocking-ruby-2-2

module PuppetEditorServices
  module Server
    class Tcp < ::PuppetEditorServices::Server::Base
      class << self
        attr_reader :io_locker, :events, :e_locker, :services, :s_locker, :io_connection_dic, :c_locker
      end

      @io_locker = Mutex.new
      @events = []
      @e_locker = Mutex.new
      @services = {}
      @s_locker = Mutex.new
      @io_connection_dic = {}
      @c_locker = Mutex.new

      def initialize(server_options, protocol_options, handler_options)
        super(server_options, {}, protocol_options, handler_options)

        add_service(server_options[:ipaddress], server_options[:port])
      end

      def name
        'TCPSRV'
      end

      ####
      # this code will be called when a socket recieves data.
      # @api private
      def get_data(io, connection_data)
        data = io.recv_nonblock(1048576) # with maximum number of bytes to read at a time...
        raise 'Received a 0byte payload' if data.length.zero?
        # We're already in a callback so no need to invoke as a callback
        connection_data[:handler].receive_data(data)
      rescue StandardError => e
        log("Closing socket due to error - #{e}\n#{e.backtrace}")
        remove_connection(io)
      end

      #########
      # main loop and activation code
      #
      # This will create a thread pool and set them running.
      # @api public
      def start
        # prepare threads
        max_threads = server_options[:max_threads] || 2
        exit_flag = false
        threads = []
        thread_cycle = proc do
          begin
            io_review
          rescue # rubocop:disable Style/RescueStandardError
            # Swallow all errors
            false
          end
          true while fire_event
        end
        max_threads.times { Thread.new { thread_cycle.call until exit_flag } }

        log('Services running. Press ^C to stop')

        # sleep until trap raises exception (cycling might cause the main thread to loose signals that might be caught inside rescue clauses)
        kill_timer = server_options[:connection_timeout]
        kill_timer = -1 if kill_timer.nil? || kill_timer < 1
        log("Will stop the server in #{server_options[:connection_timeout]} seconds if no connection is made.") if kill_timer > 0
        log('Will stop the server when client disconnects') if !server_options[:stop_on_client_exit].nil? && server_options[:stop_on_client_exit]

        # Output to STDOUT.  This is required by clients so it knows the server is now running
        self.class.s_locker.synchronize do
          self.class.services.each_value do |service|
            $stdout.write("#{server_options[:servicename]} RUNNING #{service[:hostname]}:#{service[:port]}\n")
          end
        end
        $stdout.flush

        loop do
          begin
            sleep(1)
            # The kill_timer is used to stop the server if no clients have connected in X seconds
            # a value of 0 or less will not timeout.
            if kill_timer > 0
              kill_timer -= 1
              if kill_timer.zero?
                connection_count = 0
                self.class.c_locker.synchronize { connection_count = self.class.io_connection_dic.count }
                if connection_count.zero?
                  log("No connection has been received in #{server_options[:connection_timeout]} seconds.  Shutting down server.")
                  stop_services
                end
              end
            end
          rescue # rubocop:disable Style/RescueStandardError
            # Swallow all errors
            true
          end
          break if self.class.services.empty?
        end

        # start shutdown.
        exit_flag = true
        log('Started shutdown process. Press ^C to force quit.')
        # shut down listening sockets
        stop_services
        # disconnect active connections
        stop_connections
        # cycle down threads
        log('Waiting for workers to cycle down')
        threads.each { |t| t.join if t.alive? }

        # rundown any active events
        thread_cycle.call
      end

      #######################
      ## Events (Callbacks) / Multi-tasking Platform
      # returns true if there are any unhandled events
      # @api private
      def events?
        self.class.e_locker.synchronize { !self.class.events.empty? }
      end

      # pushes an event to the event's stack
      # if a block is passed along, it will be used as a callback: the block will be called with the values returned by the handler's `call` method.
      # @api private
      def push_event(handler, *args, &block)
        if block
          self.class.e_locker.synchronize { self.class.events << [(proc { |a| push_event block, handler.call(*a) }), args] }
        else
          self.class.e_locker.synchronize { self.class.events << [handler, args] }
        end
      end

      # Runs the block asynchronously by pushing it as an event to the event's stack
      #
      # @api private
      def run_async(*args, &block)
        self.class.e_locker.synchronize { self.class.events << [block, args] } if block
        !block.nil?
      end

      # creates an asynchronous call to a method, with an optional callback (shortcut)
      # @api private
      def callback(object, method, *args, &block)
        push_event object.method(method), *args, &block
      end

      # event handling FIFO
      # @api private
      def fire_event
        event = self.class.e_locker.synchronize { self.class.events.shift }
        return false unless event
        begin
          event[0].call(*event[1])
        rescue OpenSSL::SSL::SSLError
          log('SSL Bump - SSL Certificate refused?')
        # rubocop:disable Lint/RescueException
        rescue Exception => e
          raise if e.is_a?(SignalException) || e.is_a?(SystemExit)
        end
        # rubocop:enable Lint/RescueException

        true
      end

      #####
      # Reactor
      #
      # IO review code will review the connections and sockets
      # it will accept new connections and react to socket input
      # @api private
      def io_review
        self.class.io_locker.synchronize do
          return false unless self.class.events.empty?
          united = self.class.services.keys + self.class.io_connection_dic.keys
          return false if united.empty?
          io_r = IO.select(united, nil, united, 0.1)
          if io_r
            io_r[0].each do |io|
              if self.class.services[io]
                begin
                  callback(self, :add_connection, io.accept_nonblock, self.class.services[io])
                rescue Errno::EWOULDBLOCK # rubocop:disable Lint/SuppressedException
                  # There's nothing to handle. Swallow the error
                rescue StandardError => e
                  log(e.message)
                end
              elsif self.class.io_connection_dic[io]
                callback(self, :get_data, io, self.class.io_connection_dic[io])
              else
                log('what?!')
                remove_connection(io)
                self.class.services.delete(io)
              end
            end
            io_r[2].each do |io|
              begin
                (remove_connection(io) || self.class.services.delete(io)).close
              rescue # rubocop:disable Style/RescueStandardError
                # Swallow all errors
                true
              end
            end
          end
        end
        callback self, :clear_connections
        true
      end

      #######################
      # IO - listening sockets (services)

      # @api private
      def add_service(hostname = 'localhost', port = nil, parameters = {})
        hostname = 'localhost' if hostname.nil? || hostname.empty?
        service = TCPServer.new(hostname, port)
        parameters[:hostname] = hostname
        parameters[:port] = service.local_address.ip_port
        self.class.s_locker.synchronize { self.class.services[service] = parameters }
        callback(self, :log, "Started listening on #{hostname}:#{parameters[:port]}.")
        true
      end

      # @api public
      def stop_services(from_trap = false)
        log('Stopping services')
        if from_trap
          # synchronize is not allowed when called from a trap statement
          stop_all_services
        else
          self.class.s_locker.synchronize do
            stop_all_services
          end
        end
      end

      # @api private
      def stop_all_services
        self.class.services.each do |s, p|
          begin
            s.close
          rescue # rubocop:disable Style/RescueStandardError
            # Swallow all errors
            true
          end
          log("Stopped listening on #{p[:hostname]}:#{p[:port]}")
        end
        self.class.services.clear
      end

      # @api public
      def remove_connection_async(io)
        callback(self, :remove_connection, io)
      end

      #####################
      # IO - Active connections handling

      # @api private
      def stop_connections
        self.class.c_locker.synchronize do
          self.class.io_connection_dic.each_key do |io|
            begin
              io.close
            rescue # rubocop:disable Style/RescueStandardError
              # Swallow all errors
              true
            end
          end
          self.class.io_connection_dic.clear
        end
      end

      # @api private
      def add_connection(io, service_object)
        conn = ::PuppetEditorServices::Connection::Tcp.new(self, io)
        if io
          self.class.c_locker.synchronize do
            self.class.io_connection_dic[io] = { handler: conn, service: service_object }
          end
        end
        callback(conn, :post_init)
      rescue Exception => e # rubocop:disable Lint/RescueException  Need to swallow all errors here
        callback(self, :log, "Error creating connection #{e.inspect}\n#{e.backtrace}")
      end

      # @api public
      def connection(connection_id)
        self.class.c_locker.synchronize do
          self.class.io_connection_dic.each do |_, v|
            return v[:handler] unless v[:handler].nil? || v[:handler].id != connection_id
          end
        end
        nil
      end

      # @api private
      def remove_connection(io)
        # This needs to be synchronous
        begin
          self.class.io_connection_dic[io][:handler].unbind
        rescue e
          # Any errors when unbinding the handler should NOT stop the underlying socket
          # from being closed
          log("Error unbinding #{e.inspect}\n#{e.backtrace}")
        end
        connection_count = 0
        self.class.c_locker.synchronize do
          self.class.io_connection_dic.delete io
          connection_count = self.class.io_connection_dic.count
          begin
            io.close
          rescue # rubocop:disable Style/RescueStandardError
            # Swallow all errors
            true
          end
        end

        return unless connection_count.zero? && !@server_options[:stop_on_client_exit].nil? && @server_options[:stop_on_client_exit]
        callback(self, :log, 'All clients have disconnected.  Shutting down server.')
        callback(self, :stop_services)
      end

      # clears closed connections from the stack
      # @api private
      def clear_connections
        # Using a SymbolProc here does not work
        # rubocop:disable Style/SymbolProc
        self.class.c_locker.synchronize { self.class.io_connection_dic.delete_if { |c| c.closed? } }
        # rubocop:enable Style/SymbolProc
      end
    end
  end
end

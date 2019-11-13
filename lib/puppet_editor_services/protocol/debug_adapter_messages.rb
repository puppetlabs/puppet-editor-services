# frozen_string_literal: true

module PuppetEditorServices
  module Protocol
    module DebugAdapterMessages
      # Protocol message primitives
      # interface ProtocolMessage {
      #         /** Sequence number. */
      #         seq: number;
      #         /** Message type.
      #             Values: 'request', 'response', 'event', etc.
      #         */
      #         type: string;
      #     }
      class ProtocolMessage
        attr_accessor :seq # type: number
        attr_accessor :type # type: string

        def initialize(initial_hash = nil)
          from_h!(initial_hash)
        end

        def to_json(*options)
          to_h.to_json(options)
        end

        def to_h
          {
            'seq'  => seq,
            'type' => type
          }
        end

        def from_h!(value)
          value = {} if value.nil?
          self.seq = value['seq']
          self.type = value['type']
          self
        end
      end

      # interface Request extends ProtocolMessage {
      #         /** The command to execute. */
      #         command: string;
      #         /** Object containing arguments for the command. */
      #         arguments?: any;
      #     }
      class Request < ProtocolMessage
        attr_accessor :command # type: string
        attr_accessor :arguments # type: any

        def initialize(initial_hash = nil)
          super
          self.type = 'request'
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.command = value['command']
          self.arguments = value['arguments']
          self
        end

        def to_h
          super.tap do |hash|
            hash['command'] = command
            hash['arguments'] = arguments unless arguments.nil?
          end
        end
      end

      # interface Event extends ProtocolMessage {
      #         /** Type of event. */
      #         event: string;
      #         /** Event-specific information. */
      #         body?: any;
      #     }
      class Event < ProtocolMessage
        attr_accessor :event # type: string
        attr_accessor :body # type: any

        def initialize(initial_hash = nil)
          super
          self.type = 'event'
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.event = value['event']
          self.body = value['body']
          self
        end

        def to_h
          super.tap do |hash|
            hash['event'] = event
            hash['body'] = body unless body.nil?
          end
        end
      end

      # interface Response extends ProtocolMessage {
      #         /** Sequence number of the corresponding request. */
      #         request_seq: number;
      #         /** Outcome of the request. */
      #         success: boolean;
      #         /** The command requested. */
      #         command: string;
      #         /** Contains error message if success == false. */
      #         message?: string;
      #         /** Contains request result if success is true and optional error details if success is false. */
      #         body?: any;
      #     }
      class Response < ProtocolMessage
        attr_accessor :request_seq # type: number
        attr_accessor :success # type: boolean
        attr_accessor :command # type: string
        attr_accessor :message # type: string
        attr_accessor :body # type: any

        def initialize(initial_hash = nil)
          super
          from_h!(initial_hash) unless initial_hash.nil?
          self.type = 'response'
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.request_seq = value['request_seq']
          self.success = value['success']
          self.command = value['command']
          self.message = value['message']
          self.body = value['body']
          self
        end

        def to_h
          super.tap do |hash|
            hash['request_seq'] = request_seq
            hash['success'] = success
            hash['command'] = command
            hash['message'] = message unless message.nil?
            hash['body'] = body unless body.nil?
          end
        end
      end

      # Static message generators
      def self.reply_error(request, message = nil, message_object = nil)
        Response.new(
          'request_seq' => request.seq,
          'command'     => request.command,
          'success'     => false
        ).tap do |resp|
          resp.message = message unless message.nil?
          resp.body = { 'error' => message_object } unless message_object.nil?
        end
      end

      def self.reply_success(request, body_content = nil)
        Response.new(
          'request_seq' => request.seq,
          'command'     => request.command,
          'success'     => true
        ).tap { |resp| resp.body = body_content unless body_content.nil? }
      end

      def self.new_event(event_name, body_content = nil)
        Event.new(
          'event' => event_name
        ).tap { |resp| resp.body = body_content unless body_content.nil? }
      end
    end
  end
end

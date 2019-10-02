# frozen_string_literal: true

require 'puppet_editor_services/connection/base'

module PuppetEditorServices
  module Connection
    class Stdio < ::PuppetEditorServices::Connection::Base
      def send_data(data)
        $editor_services_stdout.write(data) # rubocop:disable Style/GlobalVars  We need this global var
        true
      end

      def close_after_writing
        $editor_services_stdout.flush # rubocop:disable Style/GlobalVars  We need this global var
        server.close_connection
        true
      end

      def close
        server.close_connection
        true
      end
    end
  end
end

# frozen_string_literal: true

module PuppetLanguageServer
  class LanguageClient
    def initialize
      @client_capabilites = {}
    end

    def client_capability(*names)
      safe_hash_traverse(@client_capabilites, *names)
    end

    def send_configuration_request(message_router)
      params = LSP::ConfigurationParams.new.from_h!('items' => [])
      params.items << LSP::ConfigurationItem.new.from_h!('section' => 'puppet')

      message_router.json_rpc_handler.send_client_request('workspace/configuration', params)
      true
    end

    def parse_lsp_initialize!(initialize_params = {})
      @client_capabilites = initialize_params['capabilities']
    end

    # Settings could be a hash or an array of hash
    def parse_lsp_configuration_settings!(settings = [{}])
      # TODO: Future use. Actually do something with the settings
      # settings = [settings] unless settings.is_a?(Hash)
      # settings.each do |hash|
      # end
    end

    def register_capability(message_router, method, options = {})
      id = SecureRandom.uuid

      PuppetLanguageServer.log_message(:info, "Attempting to dynamically register the #{method} method with id #{id}")

      params = LSP::RegistrationParams.new.from_h!('registrations' => [])
      params.registrations << LSP::Registration.new.from_h!('id' => id, 'method' => method, 'registerOptions' => options)

      message_router.json_rpc_handler.send_client_request('client/registerCapability', params)
      true
    end

    def parse_register_capability_response!(message_router, _response, original_request)
      raise 'Response is not from client/registerCapability request' unless original_request['method'] == 'client/registerCapability'
      original_request['params'].registrations.each do |reg|
        PuppetLanguageServer.log_message(:info, "Succesfully dynamically registered the #{reg.method__lsp} method")
        # If we just registered the workspace/didChangeConfiguration method then
        # also trigger a configuration request to get the initial state
        send_configuration_request(message_router) if reg.method__lsp == 'workspace/didChangeConfiguration'
      end

      true
    end

    private

    def safe_hash_traverse(hash, *names)
      return nil if names.empty?
      item = nil
      loop do
        name = names.shift
        item = item.nil? ? hash[name] : item[name]
        return nil if item.nil?
        return item if names.empty?
      end
      nil
    end
  end
end

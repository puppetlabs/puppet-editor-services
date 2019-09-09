# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.configuration.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface ConfigurationClientCapabilities {
  #     /**
  #      * The workspace client capabilities
  #      */
  #     workspace?: {
  #         /**
  #         * The client supports `workspace/configuration` requests.
  #         */
  #         configuration?: boolean;
  #     };
  # }
  class ConfigurationClientCapabilities < LSPBase
    attr_accessor :workspace # type: {
    #        /**
    #        * The client supports `workspace/configuration` requests.
    #        */
    #        configuration?: boolean;
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workspace]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workspace = value['workspace'] # Unknown type
      self
    end
  end

  # export interface ConfigurationItem {
  #     /**
  #      * The scope to get the configuration section for.
  #      */
  #     scopeUri?: string;
  #     /**
  #      * The configuration section asked for.
  #      */
  #     section?: string;
  # }
  class ConfigurationItem < LSPBase
    attr_accessor :scopeUri # type: string
    attr_accessor :section # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[scopeUri section]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.scopeUri = value['scopeUri']
      self.section = value['section']
      self
    end
  end

  # export interface ConfigurationParams {
  #     items: ConfigurationItem[];
  # }
  class ConfigurationParams < LSPBase
    attr_accessor :items # type: ConfigurationItem[]

    def from_h!(value)
      value = {} if value.nil?
      self.items = to_typed_aray(value['items'], ConfigurationItem)
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments

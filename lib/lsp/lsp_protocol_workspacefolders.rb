# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.workspaceFolders.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface WorkspaceFoldersInitializeParams {
  #     /**
  #      * The actual configured workspace folders.
  #      */
  #     workspaceFolders: WorkspaceFolder[] | null;
  # }
  class WorkspaceFoldersInitializeParams < LSPBase
    attr_accessor :workspaceFolders # type: WorkspaceFolder[] | null

    def from_h!(value)
      value = {} if value.nil?
      self.workspaceFolders = value['workspaceFolders'] # Unknown type
      self
    end
  end

  # export interface WorkspaceFoldersClientCapabilities {
  #     /**
  #      * The workspace client capabilities
  #      */
  #     workspace?: {
  #         /**
  #          * The client has support for workspace folders
  #          */
  #         workspaceFolders?: boolean;
  #     };
  # }
  class WorkspaceFoldersClientCapabilities < LSPBase
    attr_accessor :workspace # type: {
    #        /**
    #         * The client has support for workspace folders
    #         */
    #        workspaceFolders?: boolean;
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

  # export interface WorkspaceFoldersServerCapabilities {
  #     /**
  #      * The workspace server capabilities
  #      */
  #     workspace?: {
  #         workspaceFolders?: {
  #             /**
  #              * The Server has support for workspace folders
  #              */
  #             supported?: boolean;
  #             /**
  #              * Whether the server wants to receive workspace folder
  #              * change notifications.
  #              *
  #              * If a strings is provided the string is treated as a ID
  #              * under which the notification is registed on the client
  #              * side. The ID can be used to unregister for these events
  #              * using the `client/unregisterCapability` request.
  #              */
  #             changeNotifications?: string | boolean;
  #         };
  #     };
  # }
  class WorkspaceFoldersServerCapabilities < LSPBase
    attr_accessor :workspace # type: {
    #        workspaceFolders?: {
    #            /**
    #             * The Server has support for workspace folders
    #             */
    #            supported?: boolean;
    #            /**
    #             * Whether the server wants to receive workspace folder
    #             * change notifications.
    #             *
    #             * If a strings is provided the string is treated as a ID
    #             * under which the notification is registed on the client
    #             * side. The ID can be used to unregister for these events
    #             * using the `client/unregisterCapability` request.
    #             */
    #            changeNotifications?: string | boolean;
    #        };
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

  # export interface WorkspaceFolder {
  #     /**
  #      * The associated URI for this workspace folder.
  #      */
  #     uri: string;
  #     /**
  #      * The name of the workspace folder. Defaults to the
  #      * uri's basename.
  #      */
  #     name: string;
  # }
  class WorkspaceFolder < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :name # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self.name = value['name']
      self
    end
  end

  # export interface DidChangeWorkspaceFoldersParams {
  #     /**
  #      * The actual workspace folder change event.
  #      */
  #     event: WorkspaceFoldersChangeEvent;
  # }
  class DidChangeWorkspaceFoldersParams < LSPBase
    attr_accessor :event # type: WorkspaceFoldersChangeEvent

    def from_h!(value)
      value = {} if value.nil?
      self.event = WorkspaceFoldersChangeEvent.new(value['event']) unless value['event'].nil?
      self
    end
  end

  # export interface WorkspaceFoldersChangeEvent {
  #     /**
  #      * The array of added workspace folders
  #      */
  #     added: WorkspaceFolder[];
  #     /**
  #      * The array of the removed workspace folders
  #      */
  #     removed: WorkspaceFolder[];
  # }
  class WorkspaceFoldersChangeEvent < LSPBase
    attr_accessor :added # type: WorkspaceFolder[]
    attr_accessor :removed # type: WorkspaceFolder[]

    def from_h!(value)
      value = {} if value.nil?
      self.added = to_typed_aray(value['added'], WorkspaceFolder)
      self.removed = to_typed_aray(value['removed'], WorkspaceFolder)
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments

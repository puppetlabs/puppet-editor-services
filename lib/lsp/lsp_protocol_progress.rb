# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.progress.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface WorkDoneProgressClientCapabilities {
  #     /**
  #      * Window specific client capabilities.
  #      */
  #     window?: {
  #         /**
  #          * Whether client supports handling progress notifications. If set servers are allowed to
  #          * report in `workDoneProgress` property in the request specific server capabilities.
  #          *
  #          * Since 3.15.0
  #          */
  #         workDoneProgress?: boolean;
  #     };
  # }
  class WorkDoneProgressClientCapabilities < LSPBase
    attr_accessor :window # type: {
    #        /**
    #         * Whether client supports handling progress notifications. If set servers are allowed to
    #         * report in `workDoneProgress` property in the request specific server capabilities.
    #         *
    #         * Since 3.15.0
    #         */
    #        workDoneProgress?: boolean;
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[window]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.window = value['window'] # Unknown type
      self
    end
  end

  # export interface WorkDoneProgressBegin {
  #     kind: 'begin';
  #     /**
  #      * Mandatory title of the progress operation. Used to briefly inform about
  #      * the kind of operation being performed.
  #      *
  #      * Examples: "Indexing" or "Linking dependencies".
  #      */
  #     title: string;
  #     /**
  #      * Controls if a cancel button should show to allow the user to cancel the
  #      * long running operation. Clients that don't support cancellation are allowed
  #      * to ignore the setting.
  #      */
  #     cancellable?: boolean;
  #     /**
  #      * Optional, more detailed associated progress message. Contains
  #      * complementary information to the `title`.
  #      *
  #      * Examples: "3/25 files", "project/src/module2", "node_modules/some_dep".
  #      * If unset, the previous progress message (if any) is still valid.
  #      */
  #     message?: string;
  #     /**
  #      * Optional progress percentage to display (value 100 is considered 100%).
  #      * If not provided infinite progress is assumed and clients are allowed
  #      * to ignore the `percentage` value in subsequent in report notifications.
  #      *
  #      * The value should be steadily rising. Clients are free to ignore values
  #      * that are not following this rule.
  #      */
  #     percentage?: number;
  # }
  class WorkDoneProgressBegin < LSPBase
    attr_accessor :kind # type: string with value 'begin'
    attr_accessor :title # type: string
    attr_accessor :cancellable # type: boolean
    attr_accessor :message # type: string
    attr_accessor :percentage # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[cancellable message percentage]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.title = value['title']
      self.cancellable = value['cancellable'] # Unknown type
      self.message = value['message']
      self.percentage = value['percentage']
      self
    end
  end

  # export interface WorkDoneProgressReport {
  #     kind: 'report';
  #     /**
  #      * Controls enablement state of a cancel button. This property is only valid if a cancel
  #      * button got requested in the `WorkDoneProgressStart` payload.
  #      *
  #      * Clients that don't support cancellation or don't support control the button's
  #      * enablement state are allowed to ignore the setting.
  #      */
  #     cancellable?: boolean;
  #     /**
  #      * Optional, more detailed associated progress message. Contains
  #      * complementary information to the `title`.
  #      *
  #      * Examples: "3/25 files", "project/src/module2", "node_modules/some_dep".
  #      * If unset, the previous progress message (if any) is still valid.
  #      */
  #     message?: string;
  #     /**
  #      * Optional progress percentage to display (value 100 is considered 100%).
  #      * If not provided infinite progress is assumed and clients are allowed
  #      * to ignore the `percentage` value in subsequent in report notifications.
  #      *
  #      * The value should be steadily rising. Clients are free to ignore values
  #      * that are not following this rule.
  #      */
  #     percentage?: number;
  # }
  class WorkDoneProgressReport < LSPBase
    attr_accessor :kind # type: string with value 'report'
    attr_accessor :cancellable # type: boolean
    attr_accessor :message # type: string
    attr_accessor :percentage # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[cancellable message percentage]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.cancellable = value['cancellable'] # Unknown type
      self.message = value['message']
      self.percentage = value['percentage']
      self
    end
  end

  # export interface WorkDoneProgressEnd {
  #     kind: 'end';
  #     /**
  #      * Optional, a final message indicating to for example indicate the outcome
  #      * of the operation.
  #      */
  #     message?: string;
  # }
  class WorkDoneProgressEnd < LSPBase
    attr_accessor :kind # type: string with value 'end'
    attr_accessor :message # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.message = value['message']
      self
    end
  end

  # export interface WorkDoneProgressCreateParams {
  #     /**
  #      * The token to be used to report progress.
  #      */
  #     token: ProgressToken;
  # }
  class WorkDoneProgressCreateParams < LSPBase
    attr_accessor :token # type: ProgressToken

    def from_h!(value)
      value = {} if value.nil?
      self.token = value['token'] # Unknown type
      self
    end
  end

  # export interface WorkDoneProgressCancelParams {
  #     /**
  #      * The token to be used to report progress.
  #      */
  #     token: ProgressToken;
  # }
  class WorkDoneProgressCancelParams < LSPBase
    attr_accessor :token # type: ProgressToken

    def from_h!(value)
      value = {} if value.nil?
      self.token = value['token'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName

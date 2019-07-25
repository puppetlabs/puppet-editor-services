# frozen_string_literal: true

# DO NOT MODIFY.This file is built automatically
# DSP Protocol: vscode-debugprotocol/lib/debugProtocol.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Layout/TrailingWhitespace

module DSP
  # interface ProtocolMessage {
  #         /** Sequence number. */
  #         seq: number;
  #         /** Message type.
  #             Values: 'request', 'response', 'event', etc.
  #         */
  #         type: string;
  #     }
  class ProtocolMessage < DSPBase
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

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
  class Request < DSPBase
    attr_accessor :command # type: string
    attr_accessor :arguments # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.command = value['command']
      self.arguments = value['arguments']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface Event extends ProtocolMessage {
  #         /** Type of event. */
  #         event: string;
  #         /** Event-specific information. */
  #         body?: any;
  #     }
  class Event < DSPBase
    attr_accessor :event # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.event = value['event']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
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
  class Response < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ErrorResponse extends Response {
  #         body: {
  #             /** An optional, structured error message. */
  #             error?: Message;
  #         };
  #     }
  class ErrorResponse < DSPBase
    attr_accessor :body # type: {
    #            /** An optional, structured error message. */
    #            error?: Message;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface InitializedEvent extends Event {
  #     }
  class InitializedEvent < DSPBase
    attr_accessor :event # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.event = value['event']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StoppedEvent extends Event {
  #         body: {
  #             /** The reason for the event.
  #                 For backward compatibility this string is shown in the UI if the 'description' attribute is missing (but it must not be translated).
  #                 Values: 'step', 'breakpoint', 'exception', 'pause', 'entry', 'goto', 'function breakpoint', 'data breakpoint', etc.
  #             */
  #             reason: string;
  #             /** The full reason for the event, e.g. 'Paused on exception'. This string is shown in the UI as is and must be translated. */
  #             description?: string;
  #             /** The thread which was stopped. */
  #             threadId?: number;
  #             /** A value of true hints to the frontend that this event should not change the focus. */
  #             preserveFocusHint?: boolean;
  #             /** Additional information. E.g. if reason is 'exception', text contains the exception name. This string is shown in the UI. */
  #             text?: string;
  #             /** If 'allThreadsStopped' is true, a debug adapter can announce that all threads have stopped.
  #                 - The client should use this information to enable that all threads can be expanded to access their stacktraces.
  #                 - If the attribute is missing or false, only the thread with the given threadId can be expanded.
  #             */
  #             allThreadsStopped?: boolean;
  #         };
  #     }
  class StoppedEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The reason for the event.
    #                For backward compatibility this string is shown in the UI if the 'description' attribute is missing (but it must not be translated).
    #                Values: 'step', 'breakpoint', 'exception', 'pause', 'entry', 'goto', 'function breakpoint', 'data breakpoint', etc.
    #            */
    #            reason: string;
    #            /** The full reason for the event, e.g. 'Paused on exception'. This string is shown in the UI as is and must be translated. */
    #            description?: string;
    #            /** The thread which was stopped. */
    #            threadId?: number;
    #            /** A value of true hints to the frontend that this event should not change the focus. */
    #            preserveFocusHint?: boolean;
    #            /** Additional information. E.g. if reason is 'exception', text contains the exception name. This string is shown in the UI. */
    #            text?: string;
    #            /** If 'allThreadsStopped' is true, a debug adapter can announce that all threads have stopped.
    #                - The client should use this information to enable that all threads can be expanded to access their stacktraces.
    #                - If the attribute is missing or false, only the thread with the given threadId can be expanded.
    #            */
    #            allThreadsStopped?: boolean;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ContinuedEvent extends Event {
  #         body: {
  #             /** The thread which was continued. */
  #             threadId: number;
  #             /** If 'allThreadsContinued' is true, a debug adapter can announce that all threads have continued. */
  #             allThreadsContinued?: boolean;
  #         };
  #     }
  class ContinuedEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The thread which was continued. */
    #            threadId: number;
    #            /** If 'allThreadsContinued' is true, a debug adapter can announce that all threads have continued. */
    #            allThreadsContinued?: boolean;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ExitedEvent extends Event {
  #         body: {
  #             /** The exit code returned from the debuggee. */
  #             exitCode: number;
  #         };
  #     }
  class ExitedEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The exit code returned from the debuggee. */
    #            exitCode: number;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface TerminatedEvent extends Event {
  #         body?: {
  #             /** A debug adapter may set 'restart' to true (or to an arbitrary object) to request that the front end restarts the session.
  #                 The value is not interpreted by the client and passed unmodified as an attribute '__restart' to the 'launch' and 'attach' requests.
  #             */
  #             restart?: any;
  #         };
  #     }
  class TerminatedEvent < DSPBase
    attr_accessor :body # type: {
    #            /** A debug adapter may set 'restart' to true (or to an arbitrary object) to request that the front end restarts the session.
    #                The value is not interpreted by the client and passed unmodified as an attribute '__restart' to the 'launch' and 'attach' requests.
    #            */
    #            restart?: any;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ThreadEvent extends Event {
  #         body: {
  #             /** The reason for the event.
  #                 Values: 'started', 'exited', etc.
  #             */
  #             reason: string;
  #             /** The identifier of the thread. */
  #             threadId: number;
  #         };
  #     }
  class ThreadEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The reason for the event.
    #                Values: 'started', 'exited', etc.
    #            */
    #            reason: string;
    #            /** The identifier of the thread. */
    #            threadId: number;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface OutputEvent extends Event {
  #         body: {
  #             /** The output category. If not specified, 'console' is assumed.
  #                 Values: 'console', 'stdout', 'stderr', 'telemetry', etc.
  #             */
  #             category?: string;
  #             /** The output to report. */
  #             output: string;
  #             /** If an attribute 'variablesReference' exists and its value is > 0, the output contains objects which can be retrieved by passing 'variablesReference' to the 'variables' request. */
  #             variablesReference?: number;
  #             /** An optional source location where the output was produced. */
  #             source?: Source;
  #             /** An optional source location line where the output was produced. */
  #             line?: number;
  #             /** An optional source location column where the output was produced. */
  #             column?: number;
  #             /** Optional data to report. For the 'telemetry' category the data will be sent to telemetry, for the other categories the data is shown in JSON format. */
  #             data?: any;
  #         };
  #     }
  class OutputEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The output category. If not specified, 'console' is assumed.
    #                Values: 'console', 'stdout', 'stderr', 'telemetry', etc.
    #            */
    #            category?: string;
    #            /** The output to report. */
    #            output: string;
    #            /** If an attribute 'variablesReference' exists and its value is > 0, the output contains objects which can be retrieved by passing 'variablesReference' to the 'variables' request. */
    #            variablesReference?: number;
    #            /** An optional source location where the output was produced. */
    #            source?: Source;
    #            /** An optional source location line where the output was produced. */
    #            line?: number;
    #            /** An optional source location column where the output was produced. */
    #            column?: number;
    #            /** Optional data to report. For the 'telemetry' category the data will be sent to telemetry, for the other categories the data is shown in JSON format. */
    #            data?: any;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface BreakpointEvent extends Event {
  #         body: {
  #             /** The reason for the event.
  #                 Values: 'changed', 'new', 'removed', etc.
  #             */
  #             reason: string;
  #             /** The 'id' attribute is used to find the target breakpoint and the other attributes are used as the new values. */
  #             breakpoint: Breakpoint;
  #         };
  #     }
  class BreakpointEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The reason for the event.
    #                Values: 'changed', 'new', 'removed', etc.
    #            */
    #            reason: string;
    #            /** The 'id' attribute is used to find the target breakpoint and the other attributes are used as the new values. */
    #            breakpoint: Breakpoint;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ModuleEvent extends Event {
  #         body: {
  #             /** The reason for the event. */
  #             reason: 'new' | 'changed' | 'removed';
  #             /** The new, changed, or removed module. In case of 'removed' only the module id is used. */
  #             module: Module;
  #         };
  #     }
  class ModuleEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The reason for the event. */
    #            reason: 'new' | 'changed' | 'removed';
    #            /** The new, changed, or removed module. In case of 'removed' only the module id is used. */
    #            module: Module;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface LoadedSourceEvent extends Event {
  #         body: {
  #             /** The reason for the event. */
  #             reason: 'new' | 'changed' | 'removed';
  #             /** The new, changed, or removed source. */
  #             source: Source;
  #         };
  #     }
  class LoadedSourceEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The reason for the event. */
    #            reason: 'new' | 'changed' | 'removed';
    #            /** The new, changed, or removed source. */
    #            source: Source;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ProcessEvent extends Event {
  #         body: {
  #             /** The logical name of the process. This is usually the full path to process's executable file. Example: /home/example/myproj/program.js. */
  #             name: string;
  #             /** The system process id of the debugged process. This property will be missing for non-system processes. */
  #             systemProcessId?: number;
  #             /** If true, the process is running on the same computer as the debug adapter. */
  #             isLocalProcess?: boolean;
  #             /** Describes how the debug engine started debugging this process.
  #                 'launch': Process was launched under the debugger.
  #                 'attach': Debugger attached to an existing process.
  #                 'attachForSuspendedLaunch': A project launcher component has launched a new process in a suspended state and then asked the debugger to attach.
  #             */
  #             startMethod?: 'launch' | 'attach' | 'attachForSuspendedLaunch';
  #             /** The size of a pointer or address for this process, in bits. This value may be used by clients when formatting addresses for display. */
  #             pointerSize?: number;
  #         };
  #     }
  class ProcessEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The logical name of the process. This is usually the full path to process's executable file. Example: /home/example/myproj/program.js. */
    #            name: string;
    #            /** The system process id of the debugged process. This property will be missing for non-system processes. */
    #            systemProcessId?: number;
    #            /** If true, the process is running on the same computer as the debug adapter. */
    #            isLocalProcess?: boolean;
    #            /** Describes how the debug engine started debugging this process.
    #                'launch': Process was launched under the debugger.
    #                'attach': Debugger attached to an existing process.
    #                'attachForSuspendedLaunch': A project launcher component has launched a new process in a suspended state and then asked the debugger to attach.
    #            */
    #            startMethod?: 'launch' | 'attach' | 'attachForSuspendedLaunch';
    #            /** The size of a pointer or address for this process, in bits. This value may be used by clients when formatting addresses for display. */
    #            pointerSize?: number;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface CapabilitiesEvent extends Event {
  #         body: {
  #             /** The set of updated capabilities. */
  #             capabilities: Capabilities;
  #         };
  #     }
  class CapabilitiesEvent < DSPBase
    attr_accessor :body # type: {
    #            /** The set of updated capabilities. */
    #            capabilities: Capabilities;
    #        }
    attr_accessor :event # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.event = value['event']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RunInTerminalRequest extends Request {
  #         arguments: RunInTerminalRequestArguments;
  #     }
  class RunInTerminalRequest < DSPBase
    attr_accessor :arguments # type: RunInTerminalRequestArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = RunInTerminalRequestArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RunInTerminalRequestArguments {
  #         /** What kind of terminal to launch. */
  #         kind?: 'integrated' | 'external';
  #         /** Optional title of the terminal. */
  #         title?: string;
  #         /** Working directory of the command. */
  #         cwd: string;
  #         /** List of arguments. The first argument is the command to run. */
  #         args: string[];
  #         /** Environment key-value pairs that are added to or removed from the default environment. */
  #         env?: {
  #             [key: string]: string | null;
  #         };
  #     }
  class RunInTerminalRequestArguments < DSPBase
    attr_accessor :kind # type: string with value 'integrated' | 'external'
    attr_accessor :title # type: string
    attr_accessor :cwd # type: string
    attr_accessor :args # type: string[]
    attr_accessor :env # type: {
    #            [key: string]: string | null;
    #        }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind title env]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.title = value['title']
      self.cwd = value['cwd']
      self.args = value['args'].map { |val| val } unless value['args'].nil?
      self.env = value['env'] # Unknown type
      self
    end
  end

  # interface RunInTerminalResponse extends Response {
  #         body: {
  #             /** The process ID. */
  #             processId?: number;
  #             /** The process ID of the terminal shell. */
  #             shellProcessId?: number;
  #         };
  #     }
  class RunInTerminalResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The process ID. */
    #            processId?: number;
    #            /** The process ID of the terminal shell. */
    #            shellProcessId?: number;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface InitializeRequest extends Request {
  #         arguments: InitializeRequestArguments;
  #     }
  class InitializeRequest < DSPBase
    attr_accessor :arguments # type: InitializeRequestArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = InitializeRequestArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface InitializeRequestArguments {
  #         /** The ID of the (frontend) client using this adapter. */
  #         clientID?: string;
  #         /** The human readable name of the (frontend) client using this adapter. */
  #         clientName?: string;
  #         /** The ID of the debug adapter. */
  #         adapterID: string;
  #         /** The ISO-639 locale of the (frontend) client using this adapter, e.g. en-US or de-CH. */
  #         locale?: string;
  #         /** If true all line numbers are 1-based (default). */
  #         linesStartAt1?: boolean;
  #         /** If true all column numbers are 1-based (default). */
  #         columnsStartAt1?: boolean;
  #         /** Determines in what format paths are specified. The default is 'path', which is the native format.
  #             Values: 'path', 'uri', etc.
  #         */
  #         pathFormat?: string;
  #         /** Client supports the optional type attribute for variables. */
  #         supportsVariableType?: boolean;
  #         /** Client supports the paging of variables. */
  #         supportsVariablePaging?: boolean;
  #         /** Client supports the runInTerminal request. */
  #         supportsRunInTerminalRequest?: boolean;
  #         /** Client supports memory references. */
  #         supportsMemoryReferences?: boolean;
  #     }
  class InitializeRequestArguments < DSPBase
    attr_accessor :clientID # type: string
    attr_accessor :clientName # type: string
    attr_accessor :adapterID # type: string
    attr_accessor :locale # type: string
    attr_accessor :linesStartAt1 # type: boolean
    attr_accessor :columnsStartAt1 # type: boolean
    attr_accessor :pathFormat # type: string
    attr_accessor :supportsVariableType # type: boolean
    attr_accessor :supportsVariablePaging # type: boolean
    attr_accessor :supportsRunInTerminalRequest # type: boolean
    attr_accessor :supportsMemoryReferences # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[clientID clientName locale linesStartAt1 columnsStartAt1 pathFormat supportsVariableType supportsVariablePaging supportsRunInTerminalRequest supportsMemoryReferences]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.clientID = value['clientID']
      self.clientName = value['clientName']
      self.adapterID = value['adapterID']
      self.locale = value['locale']
      self.linesStartAt1 = value['linesStartAt1'] # Unknown type
      self.columnsStartAt1 = value['columnsStartAt1'] # Unknown type
      self.pathFormat = value['pathFormat']
      self.supportsVariableType = value['supportsVariableType'] # Unknown type
      self.supportsVariablePaging = value['supportsVariablePaging'] # Unknown type
      self.supportsRunInTerminalRequest = value['supportsRunInTerminalRequest'] # Unknown type
      self.supportsMemoryReferences = value['supportsMemoryReferences'] # Unknown type
      self
    end
  end

  # interface InitializeResponse extends Response {
  #         /** The capabilities of this debug adapter. */
  #         body?: Capabilities;
  #     }
  class InitializeResponse < DSPBase
    attr_accessor :body # type: Capabilities
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = Capabilities.new(value['body']) unless value['body'].nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ConfigurationDoneRequest extends Request {
  #         arguments?: ConfigurationDoneArguments;
  #     }
  class ConfigurationDoneRequest < DSPBase
    attr_accessor :arguments # type: ConfigurationDoneArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ConfigurationDoneArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ConfigurationDoneArguments {
  #     }
  class ConfigurationDoneArguments < DSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # interface ConfigurationDoneResponse extends Response {
  #     }
  class ConfigurationDoneResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface LaunchRequest extends Request {
  #         arguments: LaunchRequestArguments;
  #     }
  class LaunchRequest < DSPBase
    attr_accessor :arguments # type: LaunchRequestArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = LaunchRequestArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface LaunchRequestArguments {
  #         /** If noDebug is true the launch request should launch the program without enabling debugging. */
  #         noDebug?: boolean;
  #         /** Optional data from the previous, restarted session.
  #             The data is sent as the 'restart' attribute of the 'terminated' event.
  #             The client should leave the data intact.
  #         */
  #         __restart?: any;
  #     }
  class LaunchRequestArguments < DSPBase
    attr_accessor :noDebug # type: boolean
    attr_accessor :__restart # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[noDebug __restart]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.noDebug = value['noDebug'] # Unknown type
      self.__restart = value['__restart']
      self
    end
  end

  # interface LaunchResponse extends Response {
  #     }
  class LaunchResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface AttachRequest extends Request {
  #         arguments: AttachRequestArguments;
  #     }
  class AttachRequest < DSPBase
    attr_accessor :arguments # type: AttachRequestArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = AttachRequestArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface AttachRequestArguments {
  #         /** Optional data from the previous, restarted session.
  #             The data is sent as the 'restart' attribute of the 'terminated' event.
  #             The client should leave the data intact.
  #         */
  #         __restart?: any;
  #     }
  class AttachRequestArguments < DSPBase
    attr_accessor :__restart # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[__restart]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.__restart = value['__restart']
      self
    end
  end

  # interface AttachResponse extends Response {
  #     }
  class AttachResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RestartRequest extends Request {
  #         arguments?: RestartArguments;
  #     }
  class RestartRequest < DSPBase
    attr_accessor :arguments # type: RestartArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = RestartArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RestartArguments {
  #     }
  class RestartArguments < DSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # interface RestartResponse extends Response {
  #     }
  class RestartResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DisconnectRequest extends Request {
  #         arguments?: DisconnectArguments;
  #     }
  class DisconnectRequest < DSPBase
    attr_accessor :arguments # type: DisconnectArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = DisconnectArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DisconnectArguments {
  #         /** A value of true indicates that this 'disconnect' request is part of a restart sequence. */
  #         restart?: boolean;
  #         /** Indicates whether the debuggee should be terminated when the debugger is disconnected.
  #             If unspecified, the debug adapter is free to do whatever it thinks is best.
  #             A client can only rely on this attribute being properly honored if a debug adapter returns true for the 'supportTerminateDebuggee' capability.
  #         */
  #         terminateDebuggee?: boolean;
  #     }
  class DisconnectArguments < DSPBase
    attr_accessor :restart # type: boolean
    attr_accessor :terminateDebuggee # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[restart terminateDebuggee]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.restart = value['restart'] # Unknown type
      self.terminateDebuggee = value['terminateDebuggee'] # Unknown type
      self
    end
  end

  # interface DisconnectResponse extends Response {
  #     }
  class DisconnectResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface TerminateRequest extends Request {
  #         arguments?: TerminateArguments;
  #     }
  class TerminateRequest < DSPBase
    attr_accessor :arguments # type: TerminateArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = TerminateArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface TerminateArguments {
  #         /** A value of true indicates that this 'terminate' request is part of a restart sequence. */
  #         restart?: boolean;
  #     }
  class TerminateArguments < DSPBase
    attr_accessor :restart # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[restart]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.restart = value['restart'] # Unknown type
      self
    end
  end

  # interface TerminateResponse extends Response {
  #     }
  class TerminateResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetBreakpointsRequest extends Request {
  #         arguments: SetBreakpointsArguments;
  #     }
  class SetBreakpointsRequest < DSPBase
    attr_accessor :arguments # type: SetBreakpointsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetBreakpointsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetBreakpointsArguments {
  #         /** The source location of the breakpoints; either 'source.path' or 'source.reference' must be specified. */
  #         source: Source;
  #         /** The code locations of the breakpoints. */
  #         breakpoints?: SourceBreakpoint[];
  #         /** Deprecated: The code locations of the breakpoints. */
  #         lines?: number[];
  #         /** A value of true indicates that the underlying source has been modified which results in new breakpoint locations. */
  #         sourceModified?: boolean;
  #     }
  class SetBreakpointsArguments < DSPBase
    attr_accessor :source # type: Source
    attr_accessor :breakpoints # type: SourceBreakpoint[]
    attr_accessor :lines # type: number[]
    attr_accessor :sourceModified # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[breakpoints lines sourceModified]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.breakpoints = to_typed_aray(value['breakpoints'], SourceBreakpoint)
      self.lines = value['lines'].map { |val| val } unless value['lines'].nil?
      self.sourceModified = value['sourceModified'] # Unknown type
      self
    end
  end

  # interface SetBreakpointsResponse extends Response {
  #         body: {
  #             /** Information about the breakpoints. The array elements are in the same order as the elements of the 'breakpoints' (or the deprecated 'lines') array in the arguments. */
  #             breakpoints: Breakpoint[];
  #         };
  #     }
  class SetBreakpointsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** Information about the breakpoints. The array elements are in the same order as the elements of the 'breakpoints' (or the deprecated 'lines') array in the arguments. */
    #            breakpoints: Breakpoint[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetFunctionBreakpointsRequest extends Request {
  #         arguments: SetFunctionBreakpointsArguments;
  #     }
  class SetFunctionBreakpointsRequest < DSPBase
    attr_accessor :arguments # type: SetFunctionBreakpointsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetFunctionBreakpointsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetFunctionBreakpointsArguments {
  #         /** The function names of the breakpoints. */
  #         breakpoints: FunctionBreakpoint[];
  #     }
  class SetFunctionBreakpointsArguments < DSPBase
    attr_accessor :breakpoints # type: FunctionBreakpoint[]

    def from_h!(value)
      value = {} if value.nil?
      self.breakpoints = to_typed_aray(value['breakpoints'], FunctionBreakpoint)
      self
    end
  end

  # interface SetFunctionBreakpointsResponse extends Response {
  #         body: {
  #             /** Information about the breakpoints. The array elements correspond to the elements of the 'breakpoints' array. */
  #             breakpoints: Breakpoint[];
  #         };
  #     }
  class SetFunctionBreakpointsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** Information about the breakpoints. The array elements correspond to the elements of the 'breakpoints' array. */
    #            breakpoints: Breakpoint[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetExceptionBreakpointsRequest extends Request {
  #         arguments: SetExceptionBreakpointsArguments;
  #     }
  class SetExceptionBreakpointsRequest < DSPBase
    attr_accessor :arguments # type: SetExceptionBreakpointsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetExceptionBreakpointsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetExceptionBreakpointsArguments {
  #         /** IDs of checked exception options. The set of IDs is returned via the 'exceptionBreakpointFilters' capability. */
  #         filters: string[];
  #         /** Configuration options for selected exceptions. */
  #         exceptionOptions?: ExceptionOptions[];
  #     }
  class SetExceptionBreakpointsArguments < DSPBase
    attr_accessor :filters # type: string[]
    attr_accessor :exceptionOptions # type: ExceptionOptions[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[exceptionOptions]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.filters = value['filters'].map { |val| val } unless value['filters'].nil?
      self.exceptionOptions = to_typed_aray(value['exceptionOptions'], ExceptionOptions)
      self
    end
  end

  # interface SetExceptionBreakpointsResponse extends Response {
  #     }
  class SetExceptionBreakpointsResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DataBreakpointInfoRequest extends Request {
  #         arguments: DataBreakpointInfoArguments;
  #     }
  class DataBreakpointInfoRequest < DSPBase
    attr_accessor :arguments # type: DataBreakpointInfoArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = DataBreakpointInfoArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DataBreakpointInfoArguments {
  #         /** Reference to the Variable container if the data breakpoint is requested for a child of the container. */
  #         variablesReference?: number;
  #         /** The name of the Variable's child to obtain data breakpoint information for. If variableReference isn’t provided, this can be an expression. */
  #         name: string;
  #     }
  class DataBreakpointInfoArguments < DSPBase
    attr_accessor :variablesReference # type: number
    attr_accessor :name # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[variablesReference]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.variablesReference = value['variablesReference']
      self.name = value['name']
      self
    end
  end

  # interface DataBreakpointInfoResponse extends Response {
  #         body: {
  #             /** An identifier for the data on which a data breakpoint can be registered with the setDataBreakpoints request or null if no data breakpoint is available. */
  #             dataId: string | null;
  #             /** UI string that describes on what data the breakpoint is set on or why a data breakpoint is not available. */
  #             description: string;
  #             /** Optional attribute listing the available access types for a potential data breakpoint. A UI frontend could surface this information. */
  #             accessTypes?: DataBreakpointAccessType[];
  #             /** Optional attribute indicating that a potential data breakpoint could be persisted across sessions. */
  #             canPersist?: boolean;
  #         };
  #     }
  class DataBreakpointInfoResponse < DSPBase
    attr_accessor :body # type: {
    #            /** An identifier for the data on which a data breakpoint can be registered with the setDataBreakpoints request or null if no data breakpoint is available. */
    #            dataId: string | null;
    #            /** UI string that describes on what data the breakpoint is set on or why a data breakpoint is not available. */
    #            description: string;
    #            /** Optional attribute listing the available access types for a potential data breakpoint. A UI frontend could surface this information. */
    #            accessTypes?: DataBreakpointAccessType[];
    #            /** Optional attribute indicating that a potential data breakpoint could be persisted across sessions. */
    #            canPersist?: boolean;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetDataBreakpointsRequest extends Request {
  #         arguments: SetDataBreakpointsArguments;
  #     }
  class SetDataBreakpointsRequest < DSPBase
    attr_accessor :arguments # type: SetDataBreakpointsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetDataBreakpointsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetDataBreakpointsArguments {
  #         /** The contents of this array replaces all existing data breakpoints. An empty array clears all data breakpoints. */
  #         breakpoints: DataBreakpoint[];
  #     }
  class SetDataBreakpointsArguments < DSPBase
    attr_accessor :breakpoints # type: DataBreakpoint[]

    def from_h!(value)
      value = {} if value.nil?
      self.breakpoints = to_typed_aray(value['breakpoints'], DataBreakpoint)
      self
    end
  end

  # interface SetDataBreakpointsResponse extends Response {
  #         body: {
  #             /** Information about the data breakpoints. The array elements correspond to the elements of the input argument 'breakpoints' array. */
  #             breakpoints: Breakpoint[];
  #         };
  #     }
  class SetDataBreakpointsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** Information about the data breakpoints. The array elements correspond to the elements of the input argument 'breakpoints' array. */
    #            breakpoints: Breakpoint[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ContinueRequest extends Request {
  #         arguments: ContinueArguments;
  #     }
  class ContinueRequest < DSPBase
    attr_accessor :arguments # type: ContinueArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ContinueArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ContinueArguments {
  #         /** Continue execution for the specified thread (if possible). If the backend cannot continue on a single thread but will continue on all threads, it should set the 'allThreadsContinued' attribute in the response to true. */
  #         threadId: number;
  #     }
  class ContinueArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface ContinueResponse extends Response {
  #         body: {
  #             /** If true, the 'continue' request has ignored the specified thread and continued all threads instead. If this attribute is missing a value of 'true' is assumed for backward compatibility. */
  #             allThreadsContinued?: boolean;
  #         };
  #     }
  class ContinueResponse < DSPBase
    attr_accessor :body # type: {
    #            /** If true, the 'continue' request has ignored the specified thread and continued all threads instead. If this attribute is missing a value of 'true' is assumed for backward compatibility. */
    #            allThreadsContinued?: boolean;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface NextRequest extends Request {
  #         arguments: NextArguments;
  #     }
  class NextRequest < DSPBase
    attr_accessor :arguments # type: NextArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = NextArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface NextArguments {
  #         /** Execute 'next' for this thread. */
  #         threadId: number;
  #     }
  class NextArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface NextResponse extends Response {
  #     }
  class NextResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepInRequest extends Request {
  #         arguments: StepInArguments;
  #     }
  class StepInRequest < DSPBase
    attr_accessor :arguments # type: StepInArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = StepInArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepInArguments {
  #         /** Execute 'stepIn' for this thread. */
  #         threadId: number;
  #         /** Optional id of the target to step into. */
  #         targetId?: number;
  #     }
  class StepInArguments < DSPBase
    attr_accessor :threadId # type: number
    attr_accessor :targetId # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[targetId]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self.targetId = value['targetId']
      self
    end
  end

  # interface StepInResponse extends Response {
  #     }
  class StepInResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepOutRequest extends Request {
  #         arguments: StepOutArguments;
  #     }
  class StepOutRequest < DSPBase
    attr_accessor :arguments # type: StepOutArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = StepOutArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepOutArguments {
  #         /** Execute 'stepOut' for this thread. */
  #         threadId: number;
  #     }
  class StepOutArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface StepOutResponse extends Response {
  #     }
  class StepOutResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepBackRequest extends Request {
  #         arguments: StepBackArguments;
  #     }
  class StepBackRequest < DSPBase
    attr_accessor :arguments # type: StepBackArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = StepBackArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepBackArguments {
  #         /** Execute 'stepBack' for this thread. */
  #         threadId: number;
  #     }
  class StepBackArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface StepBackResponse extends Response {
  #     }
  class StepBackResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ReverseContinueRequest extends Request {
  #         arguments: ReverseContinueArguments;
  #     }
  class ReverseContinueRequest < DSPBase
    attr_accessor :arguments # type: ReverseContinueArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ReverseContinueArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ReverseContinueArguments {
  #         /** Execute 'reverseContinue' for this thread. */
  #         threadId: number;
  #     }
  class ReverseContinueArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface ReverseContinueResponse extends Response {
  #     }
  class ReverseContinueResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RestartFrameRequest extends Request {
  #         arguments: RestartFrameArguments;
  #     }
  class RestartFrameRequest < DSPBase
    attr_accessor :arguments # type: RestartFrameArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = RestartFrameArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface RestartFrameArguments {
  #         /** Restart this stackframe. */
  #         frameId: number;
  #     }
  class RestartFrameArguments < DSPBase
    attr_accessor :frameId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.frameId = value['frameId']
      self
    end
  end

  # interface RestartFrameResponse extends Response {
  #     }
  class RestartFrameResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface GotoRequest extends Request {
  #         arguments: GotoArguments;
  #     }
  class GotoRequest < DSPBase
    attr_accessor :arguments # type: GotoArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = GotoArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface GotoArguments {
  #         /** Set the goto target for this thread. */
  #         threadId: number;
  #         /** The location where the debuggee will continue to run. */
  #         targetId: number;
  #     }
  class GotoArguments < DSPBase
    attr_accessor :threadId # type: number
    attr_accessor :targetId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self.targetId = value['targetId']
      self
    end
  end

  # interface GotoResponse extends Response {
  #     }
  class GotoResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface PauseRequest extends Request {
  #         arguments: PauseArguments;
  #     }
  class PauseRequest < DSPBase
    attr_accessor :arguments # type: PauseArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = PauseArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface PauseArguments {
  #         /** Pause execution for this thread. */
  #         threadId: number;
  #     }
  class PauseArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface PauseResponse extends Response {
  #     }
  class PauseResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StackTraceRequest extends Request {
  #         arguments: StackTraceArguments;
  #     }
  class StackTraceRequest < DSPBase
    attr_accessor :arguments # type: StackTraceArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = StackTraceArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StackTraceArguments {
  #         /** Retrieve the stacktrace for this thread. */
  #         threadId: number;
  #         /** The index of the first frame to return; if omitted frames start at 0. */
  #         startFrame?: number;
  #         /** The maximum number of frames to return. If levels is not specified or 0, all frames are returned. */
  #         levels?: number;
  #         /** Specifies details on how to format the stack frames. */
  #         format?: StackFrameFormat;
  #     }
  class StackTraceArguments < DSPBase
    attr_accessor :threadId # type: number
    attr_accessor :startFrame # type: number
    attr_accessor :levels # type: number
    attr_accessor :format # type: StackFrameFormat

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[startFrame levels format]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self.startFrame = value['startFrame']
      self.levels = value['levels']
      self.format = StackFrameFormat.new(value['format']) unless value['format'].nil?
      self
    end
  end

  # interface StackTraceResponse extends Response {
  #         body: {
  #             /** The frames of the stackframe. If the array has length zero, there are no stackframes available.
  #                 This means that there is no location information available.
  #             */
  #             stackFrames: StackFrame[];
  #             /** The total number of frames available. */
  #             totalFrames?: number;
  #         };
  #     }
  class StackTraceResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The frames of the stackframe. If the array has length zero, there are no stackframes available.
    #                This means that there is no location information available.
    #            */
    #            stackFrames: StackFrame[];
    #            /** The total number of frames available. */
    #            totalFrames?: number;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ScopesRequest extends Request {
  #         arguments: ScopesArguments;
  #     }
  class ScopesRequest < DSPBase
    attr_accessor :arguments # type: ScopesArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ScopesArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ScopesArguments {
  #         /** Retrieve the scopes for this stackframe. */
  #         frameId: number;
  #     }
  class ScopesArguments < DSPBase
    attr_accessor :frameId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.frameId = value['frameId']
      self
    end
  end

  # interface ScopesResponse extends Response {
  #         body: {
  #             /** The scopes of the stackframe. If the array has length zero, there are no scopes available. */
  #             scopes: Scope[];
  #         };
  #     }
  class ScopesResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The scopes of the stackframe. If the array has length zero, there are no scopes available. */
    #            scopes: Scope[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface VariablesRequest extends Request {
  #         arguments: VariablesArguments;
  #     }
  class VariablesRequest < DSPBase
    attr_accessor :arguments # type: VariablesArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = VariablesArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface VariablesArguments {
  #         /** The Variable reference. */
  #         variablesReference: number;
  #         /** Optional filter to limit the child variables to either named or indexed. If ommited, both types are fetched. */
  #         filter?: 'indexed' | 'named';
  #         /** The index of the first variable to return; if omitted children start at 0. */
  #         start?: number;
  #         /** The number of variables to return. If count is missing or 0, all variables are returned. */
  #         count?: number;
  #         /** Specifies details on how to format the Variable values. */
  #         format?: ValueFormat;
  #     }
  class VariablesArguments < DSPBase
    attr_accessor :variablesReference # type: number
    attr_accessor :filter # type: string with value 'indexed' | 'named'
    attr_accessor :start # type: number
    attr_accessor :count # type: number
    attr_accessor :format # type: ValueFormat

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[filter start count format]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.variablesReference = value['variablesReference']
      self.filter = value['filter'] # Unknown type
      self.start = value['start']
      self.count = value['count']
      self.format = ValueFormat.new(value['format']) unless value['format'].nil?
      self
    end
  end

  # interface VariablesResponse extends Response {
  #         body: {
  #             /** All (or a range) of variables for the given variable reference. */
  #             variables: Variable[];
  #         };
  #     }
  class VariablesResponse < DSPBase
    attr_accessor :body # type: {
    #            /** All (or a range) of variables for the given variable reference. */
    #            variables: Variable[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetVariableRequest extends Request {
  #         arguments: SetVariableArguments;
  #     }
  class SetVariableRequest < DSPBase
    attr_accessor :arguments # type: SetVariableArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetVariableArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetVariableArguments {
  #         /** The reference of the variable container. */
  #         variablesReference: number;
  #         /** The name of the variable in the container. */
  #         name: string;
  #         /** The value of the variable. */
  #         value: string;
  #         /** Specifies details on how to format the response value. */
  #         format?: ValueFormat;
  #     }
  class SetVariableArguments < DSPBase
    attr_accessor :variablesReference # type: number
    attr_accessor :name # type: string
    attr_accessor :value # type: string
    attr_accessor :format # type: ValueFormat

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[format]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.variablesReference = value['variablesReference']
      self.name = value['name']
      self.value = value['value']
      self.format = ValueFormat.new(value['format']) unless value['format'].nil?
      self
    end
  end

  # interface SetVariableResponse extends Response {
  #         body: {
  #             /** The new value of the variable. */
  #             value: string;
  #             /** The type of the new value. Typically shown in the UI when hovering over the value. */
  #             type?: string;
  #             /** If variablesReference is > 0, the new value is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
  #             variablesReference?: number;
  #             /** The number of named child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             namedVariables?: number;
  #             /** The number of indexed child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             indexedVariables?: number;
  #         };
  #     }
  class SetVariableResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The new value of the variable. */
    #            value: string;
    #            /** The type of the new value. Typically shown in the UI when hovering over the value. */
    #            type?: string;
    #            /** If variablesReference is > 0, the new value is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
    #            variablesReference?: number;
    #            /** The number of named child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            namedVariables?: number;
    #            /** The number of indexed child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            indexedVariables?: number;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SourceRequest extends Request {
  #         arguments: SourceArguments;
  #     }
  class SourceRequest < DSPBase
    attr_accessor :arguments # type: SourceArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SourceArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SourceArguments {
  #         /** Specifies the source content to load. Either source.path or source.sourceReference must be specified. */
  #         source?: Source;
  #         /** The reference to the source. This is the same as source.sourceReference. This is provided for backward compatibility since old backends do not understand the 'source' attribute. */
  #         sourceReference: number;
  #     }
  class SourceArguments < DSPBase
    attr_accessor :source # type: Source
    attr_accessor :sourceReference # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[source]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.sourceReference = value['sourceReference']
      self
    end
  end

  # interface SourceResponse extends Response {
  #         body: {
  #             /** Content of the source reference. */
  #             content: string;
  #             /** Optional content type (mime type) of the source. */
  #             mimeType?: string;
  #         };
  #     }
  class SourceResponse < DSPBase
    attr_accessor :body # type: {
    #            /** Content of the source reference. */
    #            content: string;
    #            /** Optional content type (mime type) of the source. */
    #            mimeType?: string;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ThreadsRequest extends Request {
  #     }
  class ThreadsRequest < DSPBase
    attr_accessor :command # type: string
    attr_accessor :arguments # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.command = value['command']
      self.arguments = value['arguments']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ThreadsResponse extends Response {
  #         body: {
  #             /** All threads. */
  #             threads: Thread[];
  #         };
  #     }
  class ThreadsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** All threads. */
    #            threads: Thread[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface TerminateThreadsRequest extends Request {
  #         arguments: TerminateThreadsArguments;
  #     }
  class TerminateThreadsRequest < DSPBase
    attr_accessor :arguments # type: TerminateThreadsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = TerminateThreadsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface TerminateThreadsArguments {
  #         /** Ids of threads to be terminated. */
  #         threadIds?: number[];
  #     }
  class TerminateThreadsArguments < DSPBase
    attr_accessor :threadIds # type: number[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[threadIds]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.threadIds = value['threadIds'].map { |val| val } unless value['threadIds'].nil?
      self
    end
  end

  # interface TerminateThreadsResponse extends Response {
  #     }
  class TerminateThreadsResponse < DSPBase
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :body # type: any
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message body]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.body = value['body']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ModulesRequest extends Request {
  #         arguments: ModulesArguments;
  #     }
  class ModulesRequest < DSPBase
    attr_accessor :arguments # type: ModulesArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ModulesArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ModulesArguments {
  #         /** The index of the first module to return; if omitted modules start at 0. */
  #         startModule?: number;
  #         /** The number of modules to return. If moduleCount is not specified or 0, all modules are returned. */
  #         moduleCount?: number;
  #     }
  class ModulesArguments < DSPBase
    attr_accessor :startModule # type: number
    attr_accessor :moduleCount # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[startModule moduleCount]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.startModule = value['startModule']
      self.moduleCount = value['moduleCount']
      self
    end
  end

  # interface ModulesResponse extends Response {
  #         body: {
  #             /** All modules or range of modules. */
  #             modules: Module[];
  #             /** The total number of modules available. */
  #             totalModules?: number;
  #         };
  #     }
  class ModulesResponse < DSPBase
    attr_accessor :body # type: {
    #            /** All modules or range of modules. */
    #            modules: Module[];
    #            /** The total number of modules available. */
    #            totalModules?: number;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface LoadedSourcesRequest extends Request {
  #         arguments?: LoadedSourcesArguments;
  #     }
  class LoadedSourcesRequest < DSPBase
    attr_accessor :arguments # type: LoadedSourcesArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = LoadedSourcesArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface LoadedSourcesArguments {
  #     }
  class LoadedSourcesArguments < DSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # interface LoadedSourcesResponse extends Response {
  #         body: {
  #             /** Set of loaded sources. */
  #             sources: Source[];
  #         };
  #     }
  class LoadedSourcesResponse < DSPBase
    attr_accessor :body # type: {
    #            /** Set of loaded sources. */
    #            sources: Source[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface EvaluateRequest extends Request {
  #         arguments: EvaluateArguments;
  #     }
  class EvaluateRequest < DSPBase
    attr_accessor :arguments # type: EvaluateArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = EvaluateArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface EvaluateArguments {
  #         /** The expression to evaluate. */
  #         expression: string;
  #         /** Evaluate the expression in the scope of this stack frame. If not specified, the expression is evaluated in the global scope. */
  #         frameId?: number;
  #         /** The context in which the evaluate request is run.
  #             Values:
  #             'watch': evaluate is run in a watch.
  #             'repl': evaluate is run from REPL console.
  #             'hover': evaluate is run from a data hover.
  #             etc.
  #         */
  #         context?: string;
  #         /** Specifies details on how to format the Evaluate result. */
  #         format?: ValueFormat;
  #     }
  class EvaluateArguments < DSPBase
    attr_accessor :expression # type: string
    attr_accessor :frameId # type: number
    attr_accessor :context # type: string
    attr_accessor :format # type: ValueFormat

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[frameId context format]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.expression = value['expression']
      self.frameId = value['frameId']
      self.context = value['context']
      self.format = ValueFormat.new(value['format']) unless value['format'].nil?
      self
    end
  end

  # interface EvaluateResponse extends Response {
  #         body: {
  #             /** The result of the evaluate request. */
  #             result: string;
  #             /** The optional type of the evaluate result. */
  #             type?: string;
  #             /** Properties of a evaluate result that can be used to determine how to render the result in the UI. */
  #             presentationHint?: VariablePresentationHint;
  #             /** If variablesReference is > 0, the evaluate result is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
  #             variablesReference: number;
  #             /** The number of named child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             namedVariables?: number;
  #             /** The number of indexed child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             indexedVariables?: number;
  #             /** Memory reference to a location appropriate for this result. For pointer type eval results, this is generally a reference to the memory address contained in the pointer. */
  #             memoryReference?: string;
  #         };
  #     }
  class EvaluateResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The result of the evaluate request. */
    #            result: string;
    #            /** The optional type of the evaluate result. */
    #            type?: string;
    #            /** Properties of a evaluate result that can be used to determine how to render the result in the UI. */
    #            presentationHint?: VariablePresentationHint;
    #            /** If variablesReference is > 0, the evaluate result is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
    #            variablesReference: number;
    #            /** The number of named child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            namedVariables?: number;
    #            /** The number of indexed child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            indexedVariables?: number;
    #            /** Memory reference to a location appropriate for this result. For pointer type eval results, this is generally a reference to the memory address contained in the pointer. */
    #            memoryReference?: string;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetExpressionRequest extends Request {
  #         arguments: SetExpressionArguments;
  #     }
  class SetExpressionRequest < DSPBase
    attr_accessor :arguments # type: SetExpressionArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = SetExpressionArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface SetExpressionArguments {
  #         /** The l-value expression to assign to. */
  #         expression: string;
  #         /** The value expression to assign to the l-value expression. */
  #         value: string;
  #         /** Evaluate the expressions in the scope of this stack frame. If not specified, the expressions are evaluated in the global scope. */
  #         frameId?: number;
  #         /** Specifies how the resulting value should be formatted. */
  #         format?: ValueFormat;
  #     }
  class SetExpressionArguments < DSPBase
    attr_accessor :expression # type: string
    attr_accessor :value # type: string
    attr_accessor :frameId # type: number
    attr_accessor :format # type: ValueFormat

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[frameId format]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.expression = value['expression']
      self.value = value['value']
      self.frameId = value['frameId']
      self.format = ValueFormat.new(value['format']) unless value['format'].nil?
      self
    end
  end

  # interface SetExpressionResponse extends Response {
  #         body: {
  #             /** The new value of the expression. */
  #             value: string;
  #             /** The optional type of the value. */
  #             type?: string;
  #             /** Properties of a value that can be used to determine how to render the result in the UI. */
  #             presentationHint?: VariablePresentationHint;
  #             /** If variablesReference is > 0, the value is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
  #             variablesReference?: number;
  #             /** The number of named child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             namedVariables?: number;
  #             /** The number of indexed child variables.
  #                 The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #             */
  #             indexedVariables?: number;
  #         };
  #     }
  class SetExpressionResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The new value of the expression. */
    #            value: string;
    #            /** The optional type of the value. */
    #            type?: string;
    #            /** Properties of a value that can be used to determine how to render the result in the UI. */
    #            presentationHint?: VariablePresentationHint;
    #            /** If variablesReference is > 0, the value is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
    #            variablesReference?: number;
    #            /** The number of named child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            namedVariables?: number;
    #            /** The number of indexed child variables.
    #                The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
    #            */
    #            indexedVariables?: number;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepInTargetsRequest extends Request {
  #         arguments: StepInTargetsArguments;
  #     }
  class StepInTargetsRequest < DSPBase
    attr_accessor :arguments # type: StepInTargetsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = StepInTargetsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface StepInTargetsArguments {
  #         /** The stack frame for which to retrieve the possible stepIn targets. */
  #         frameId: number;
  #     }
  class StepInTargetsArguments < DSPBase
    attr_accessor :frameId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.frameId = value['frameId']
      self
    end
  end

  # interface StepInTargetsResponse extends Response {
  #         body: {
  #             /** The possible stepIn targets of the specified source location. */
  #             targets: StepInTarget[];
  #         };
  #     }
  class StepInTargetsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The possible stepIn targets of the specified source location. */
    #            targets: StepInTarget[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface GotoTargetsRequest extends Request {
  #         arguments: GotoTargetsArguments;
  #     }
  class GotoTargetsRequest < DSPBase
    attr_accessor :arguments # type: GotoTargetsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = GotoTargetsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface GotoTargetsArguments {
  #         /** The source location for which the goto targets are determined. */
  #         source: Source;
  #         /** The line location for which the goto targets are determined. */
  #         line: number;
  #         /** An optional column location for which the goto targets are determined. */
  #         column?: number;
  #     }
  class GotoTargetsArguments < DSPBase
    attr_accessor :source # type: Source
    attr_accessor :line # type: number
    attr_accessor :column # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[column]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.line = value['line']
      self.column = value['column']
      self
    end
  end

  # interface GotoTargetsResponse extends Response {
  #         body: {
  #             /** The possible goto targets of the specified location. */
  #             targets: GotoTarget[];
  #         };
  #     }
  class GotoTargetsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The possible goto targets of the specified location. */
    #            targets: GotoTarget[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface CompletionsRequest extends Request {
  #         arguments: CompletionsArguments;
  #     }
  class CompletionsRequest < DSPBase
    attr_accessor :arguments # type: CompletionsArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = CompletionsArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface CompletionsArguments {
  #         /** Returns completions in the scope of this stack frame. If not specified, the completions are returned for the global scope. */
  #         frameId?: number;
  #         /** One or more source lines. Typically this is the text a user has typed into the debug console before he asked for completion. */
  #         text: string;
  #         /** The character position for which to determine the completion proposals. */
  #         column: number;
  #         /** An optional line for which to determine the completion proposals. If missing the first line of the text is assumed. */
  #         line?: number;
  #     }
  class CompletionsArguments < DSPBase
    attr_accessor :frameId # type: number
    attr_accessor :text # type: string
    attr_accessor :column # type: number
    attr_accessor :line # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[frameId line]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.frameId = value['frameId']
      self.text = value['text']
      self.column = value['column']
      self.line = value['line']
      self
    end
  end

  # interface CompletionsResponse extends Response {
  #         body: {
  #             /** The possible completions for . */
  #             targets: CompletionItem[];
  #         };
  #     }
  class CompletionsResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The possible completions for . */
    #            targets: CompletionItem[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ExceptionInfoRequest extends Request {
  #         arguments: ExceptionInfoArguments;
  #     }
  class ExceptionInfoRequest < DSPBase
    attr_accessor :arguments # type: ExceptionInfoArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ExceptionInfoArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ExceptionInfoArguments {
  #         /** Thread for which exception information should be retrieved. */
  #         threadId: number;
  #     }
  class ExceptionInfoArguments < DSPBase
    attr_accessor :threadId # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.threadId = value['threadId']
      self
    end
  end

  # interface ExceptionInfoResponse extends Response {
  #         body: {
  #             /** ID of the exception that was thrown. */
  #             exceptionId: string;
  #             /** Descriptive text for the exception provided by the debug adapter. */
  #             description?: string;
  #             /** Mode that caused the exception notification to be raised. */
  #             breakMode: ExceptionBreakMode;
  #             /** Detailed information about the exception. */
  #             details?: ExceptionDetails;
  #         };
  #     }
  class ExceptionInfoResponse < DSPBase
    attr_accessor :body # type: {
    #            /** ID of the exception that was thrown. */
    #            exceptionId: string;
    #            /** Descriptive text for the exception provided by the debug adapter. */
    #            description?: string;
    #            /** Mode that caused the exception notification to be raised. */
    #            breakMode: ExceptionBreakMode;
    #            /** Detailed information about the exception. */
    #            details?: ExceptionDetails;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ReadMemoryRequest extends Request {
  #         arguments: ReadMemoryArguments;
  #     }
  class ReadMemoryRequest < DSPBase
    attr_accessor :arguments # type: ReadMemoryArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = ReadMemoryArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface ReadMemoryArguments {
  #         /** Memory reference to the base location from which data should be read. */
  #         memoryReference: string;
  #         /** Optional offset (in bytes) to be applied to the reference location before reading data. Can be negative. */
  #         offset?: number;
  #         /** Number of bytes to read at the specified location and offset. */
  #         count: number;
  #     }
  class ReadMemoryArguments < DSPBase
    attr_accessor :memoryReference # type: string
    attr_accessor :offset # type: number
    attr_accessor :count # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[offset]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.memoryReference = value['memoryReference']
      self.offset = value['offset']
      self.count = value['count']
      self
    end
  end

  # interface ReadMemoryResponse extends Response {
  #         body?: {
  #             /** The address of the first byte of data returned. Treated as a hex value if prefixed with '0x', or as a decimal value otherwise. */
  #             address: string;
  #             /** The number of unreadable bytes encountered after the last successfully read byte. This can be used to determine the number of bytes that must be skipped before a subsequent 'readMemory' request will succeed. */
  #             unreadableBytes?: number;
  #             /** The bytes read from memory, encoded using base64. */
  #             data?: string;
  #         };
  #     }
  class ReadMemoryResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The address of the first byte of data returned. Treated as a hex value if prefixed with '0x', or as a decimal value otherwise. */
    #            address: string;
    #            /** The number of unreadable bytes encountered after the last successfully read byte. This can be used to determine the number of bytes that must be skipped before a subsequent 'readMemory' request will succeed. */
    #            unreadableBytes?: number;
    #            /** The bytes read from memory, encoded using base64. */
    #            data?: string;
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DisassembleRequest extends Request {
  #         arguments: DisassembleArguments;
  #     }
  class DisassembleRequest < DSPBase
    attr_accessor :arguments # type: DisassembleArguments
    attr_accessor :command # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.arguments = DisassembleArguments.new(value['arguments']) unless value['arguments'].nil?
      self.command = value['command']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface DisassembleArguments {
  #         /** Memory reference to the base location containing the instructions to disassemble. */
  #         memoryReference: string;
  #         /** Optional offset (in bytes) to be applied to the reference location before disassembling. Can be negative. */
  #         offset?: number;
  #         /** Optional offset (in instructions) to be applied after the byte offset (if any) before disassembling. Can be negative. */
  #         instructionOffset?: number;
  #         /** Number of instructions to disassemble starting at the specified location and offset. An adapter must return exactly this number of instructions - any unavailable instructions should be replaced with an implementation-defined 'invalid instruction' value. */
  #         instructionCount: number;
  #         /** If true, the adapter should attempt to resolve memory addresses and other values to symbolic names. */
  #         resolveSymbols?: boolean;
  #     }
  class DisassembleArguments < DSPBase
    attr_accessor :memoryReference # type: string
    attr_accessor :offset # type: number
    attr_accessor :instructionOffset # type: number
    attr_accessor :instructionCount # type: number
    attr_accessor :resolveSymbols # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[offset instructionOffset resolveSymbols]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.memoryReference = value['memoryReference']
      self.offset = value['offset']
      self.instructionOffset = value['instructionOffset']
      self.instructionCount = value['instructionCount']
      self.resolveSymbols = value['resolveSymbols'] # Unknown type
      self
    end
  end

  # interface DisassembleResponse extends Response {
  #         body?: {
  #             /** The list of disassembled instructions. */
  #             instructions: DisassembledInstruction[];
  #         };
  #     }
  class DisassembleResponse < DSPBase
    attr_accessor :body # type: {
    #            /** The list of disassembled instructions. */
    #            instructions: DisassembledInstruction[];
    #        }
    attr_accessor :request_seq # type: number
    attr_accessor :success # type: boolean
    attr_accessor :command # type: string
    attr_accessor :message # type: string
    attr_accessor :seq # type: number
    attr_accessor :type # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[body message]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.body = value['body'] # Unknown type
      self.request_seq = value['request_seq']
      self.success = value['success'] # Unknown type
      self.command = value['command']
      self.message = value['message']
      self.seq = value['seq']
      self.type = value['type']
      self
    end
  end

  # interface Capabilities {
  #         /** The debug adapter supports the 'configurationDone' request. */
  #         supportsConfigurationDoneRequest?: boolean;
  #         /** The debug adapter supports function breakpoints. */
  #         supportsFunctionBreakpoints?: boolean;
  #         /** The debug adapter supports conditional breakpoints. */
  #         supportsConditionalBreakpoints?: boolean;
  #         /** The debug adapter supports breakpoints that break execution after a specified number of hits. */
  #         supportsHitConditionalBreakpoints?: boolean;
  #         /** The debug adapter supports a (side effect free) evaluate request for data hovers. */
  #         supportsEvaluateForHovers?: boolean;
  #         /** Available filters or options for the setExceptionBreakpoints request. */
  #         exceptionBreakpointFilters?: ExceptionBreakpointsFilter[];
  #         /** The debug adapter supports stepping back via the 'stepBack' and 'reverseContinue' requests. */
  #         supportsStepBack?: boolean;
  #         /** The debug adapter supports setting a variable to a value. */
  #         supportsSetVariable?: boolean;
  #         /** The debug adapter supports restarting a frame. */
  #         supportsRestartFrame?: boolean;
  #         /** The debug adapter supports the 'gotoTargets' request. */
  #         supportsGotoTargetsRequest?: boolean;
  #         /** The debug adapter supports the 'stepInTargets' request. */
  #         supportsStepInTargetsRequest?: boolean;
  #         /** The debug adapter supports the 'completions' request. */
  #         supportsCompletionsRequest?: boolean;
  #         /** The debug adapter supports the 'modules' request. */
  #         supportsModulesRequest?: boolean;
  #         /** The set of additional module information exposed by the debug adapter. */
  #         additionalModuleColumns?: ColumnDescriptor[];
  #         /** Checksum algorithms supported by the debug adapter. */
  #         supportedChecksumAlgorithms?: ChecksumAlgorithm[];
  #         /** The debug adapter supports the 'restart' request. In this case a client should not implement 'restart' by terminating and relaunching the adapter but by calling the RestartRequest. */
  #         supportsRestartRequest?: boolean;
  #         /** The debug adapter supports 'exceptionOptions' on the setExceptionBreakpoints request. */
  #         supportsExceptionOptions?: boolean;
  #         /** The debug adapter supports a 'format' attribute on the stackTraceRequest, variablesRequest, and evaluateRequest. */
  #         supportsValueFormattingOptions?: boolean;
  #         /** The debug adapter supports the 'exceptionInfo' request. */
  #         supportsExceptionInfoRequest?: boolean;
  #         /** The debug adapter supports the 'terminateDebuggee' attribute on the 'disconnect' request. */
  #         supportTerminateDebuggee?: boolean;
  #         /** The debug adapter supports the delayed loading of parts of the stack, which requires that both the 'startFrame' and 'levels' arguments and the 'totalFrames' result of the 'StackTrace' request are supported. */
  #         supportsDelayedStackTraceLoading?: boolean;
  #         /** The debug adapter supports the 'loadedSources' request. */
  #         supportsLoadedSourcesRequest?: boolean;
  #         /** The debug adapter supports logpoints by interpreting the 'logMessage' attribute of the SourceBreakpoint. */
  #         supportsLogPoints?: boolean;
  #         /** The debug adapter supports the 'terminateThreads' request. */
  #         supportsTerminateThreadsRequest?: boolean;
  #         /** The debug adapter supports the 'setExpression' request. */
  #         supportsSetExpression?: boolean;
  #         /** The debug adapter supports the 'terminate' request. */
  #         supportsTerminateRequest?: boolean;
  #         /** The debug adapter supports data breakpoints. */
  #         supportsDataBreakpoints?: boolean;
  #         /** The debug adapter supports the 'readMemory' request. */
  #         supportsReadMemoryRequest?: boolean;
  #         /** The debug adapter supports the 'disassemble' request. */
  #         supportsDisassembleRequest?: boolean;
  #     }
  class Capabilities < DSPBase
    attr_accessor :supportsConfigurationDoneRequest # type: boolean
    attr_accessor :supportsFunctionBreakpoints # type: boolean
    attr_accessor :supportsConditionalBreakpoints # type: boolean
    attr_accessor :supportsHitConditionalBreakpoints # type: boolean
    attr_accessor :supportsEvaluateForHovers # type: boolean
    attr_accessor :exceptionBreakpointFilters # type: ExceptionBreakpointsFilter[]
    attr_accessor :supportsStepBack # type: boolean
    attr_accessor :supportsSetVariable # type: boolean
    attr_accessor :supportsRestartFrame # type: boolean
    attr_accessor :supportsGotoTargetsRequest # type: boolean
    attr_accessor :supportsStepInTargetsRequest # type: boolean
    attr_accessor :supportsCompletionsRequest # type: boolean
    attr_accessor :supportsModulesRequest # type: boolean
    attr_accessor :additionalModuleColumns # type: ColumnDescriptor[]
    attr_accessor :supportedChecksumAlgorithms # type: ChecksumAlgorithm[]
    attr_accessor :supportsRestartRequest # type: boolean
    attr_accessor :supportsExceptionOptions # type: boolean
    attr_accessor :supportsValueFormattingOptions # type: boolean
    attr_accessor :supportsExceptionInfoRequest # type: boolean
    attr_accessor :supportTerminateDebuggee # type: boolean
    attr_accessor :supportsDelayedStackTraceLoading # type: boolean
    attr_accessor :supportsLoadedSourcesRequest # type: boolean
    attr_accessor :supportsLogPoints # type: boolean
    attr_accessor :supportsTerminateThreadsRequest # type: boolean
    attr_accessor :supportsSetExpression # type: boolean
    attr_accessor :supportsTerminateRequest # type: boolean
    attr_accessor :supportsDataBreakpoints # type: boolean
    attr_accessor :supportsReadMemoryRequest # type: boolean
    attr_accessor :supportsDisassembleRequest # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[supportsConfigurationDoneRequest supportsFunctionBreakpoints supportsConditionalBreakpoints supportsHitConditionalBreakpoints supportsEvaluateForHovers exceptionBreakpointFilters supportsStepBack supportsSetVariable supportsRestartFrame supportsGotoTargetsRequest supportsStepInTargetsRequest supportsCompletionsRequest supportsModulesRequest additionalModuleColumns supportedChecksumAlgorithms supportsRestartRequest supportsExceptionOptions supportsValueFormattingOptions supportsExceptionInfoRequest supportTerminateDebuggee supportsDelayedStackTraceLoading supportsLoadedSourcesRequest supportsLogPoints supportsTerminateThreadsRequest supportsSetExpression supportsTerminateRequest supportsDataBreakpoints supportsReadMemoryRequest supportsDisassembleRequest]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.supportsConfigurationDoneRequest = value['supportsConfigurationDoneRequest'] # Unknown type
      self.supportsFunctionBreakpoints = value['supportsFunctionBreakpoints'] # Unknown type
      self.supportsConditionalBreakpoints = value['supportsConditionalBreakpoints'] # Unknown type
      self.supportsHitConditionalBreakpoints = value['supportsHitConditionalBreakpoints'] # Unknown type
      self.supportsEvaluateForHovers = value['supportsEvaluateForHovers'] # Unknown type
      self.exceptionBreakpointFilters = to_typed_aray(value['exceptionBreakpointFilters'], ExceptionBreakpointsFilter)
      self.supportsStepBack = value['supportsStepBack'] # Unknown type
      self.supportsSetVariable = value['supportsSetVariable'] # Unknown type
      self.supportsRestartFrame = value['supportsRestartFrame'] # Unknown type
      self.supportsGotoTargetsRequest = value['supportsGotoTargetsRequest'] # Unknown type
      self.supportsStepInTargetsRequest = value['supportsStepInTargetsRequest'] # Unknown type
      self.supportsCompletionsRequest = value['supportsCompletionsRequest'] # Unknown type
      self.supportsModulesRequest = value['supportsModulesRequest'] # Unknown type
      self.additionalModuleColumns = to_typed_aray(value['additionalModuleColumns'], ColumnDescriptor)
      self.supportedChecksumAlgorithms = value['supportedChecksumAlgorithms'].map { |val| val } unless value['supportedChecksumAlgorithms'].nil? # Unknown array type
      self.supportsRestartRequest = value['supportsRestartRequest'] # Unknown type
      self.supportsExceptionOptions = value['supportsExceptionOptions'] # Unknown type
      self.supportsValueFormattingOptions = value['supportsValueFormattingOptions'] # Unknown type
      self.supportsExceptionInfoRequest = value['supportsExceptionInfoRequest'] # Unknown type
      self.supportTerminateDebuggee = value['supportTerminateDebuggee'] # Unknown type
      self.supportsDelayedStackTraceLoading = value['supportsDelayedStackTraceLoading'] # Unknown type
      self.supportsLoadedSourcesRequest = value['supportsLoadedSourcesRequest'] # Unknown type
      self.supportsLogPoints = value['supportsLogPoints'] # Unknown type
      self.supportsTerminateThreadsRequest = value['supportsTerminateThreadsRequest'] # Unknown type
      self.supportsSetExpression = value['supportsSetExpression'] # Unknown type
      self.supportsTerminateRequest = value['supportsTerminateRequest'] # Unknown type
      self.supportsDataBreakpoints = value['supportsDataBreakpoints'] # Unknown type
      self.supportsReadMemoryRequest = value['supportsReadMemoryRequest'] # Unknown type
      self.supportsDisassembleRequest = value['supportsDisassembleRequest'] # Unknown type
      self
    end
  end

  # interface ExceptionBreakpointsFilter {
  #         /** The internal ID of the filter. This value is passed to the setExceptionBreakpoints request. */
  #         filter: string;
  #         /** The name of the filter. This will be shown in the UI. */
  #         label: string;
  #         /** Initial value of the filter. If not specified a value 'false' is assumed. */
  #         default?: boolean;
  #     }
  class ExceptionBreakpointsFilter < DSPBase
    attr_accessor :filter # type: string
    attr_accessor :label # type: string
    attr_accessor :default # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[default]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.filter = value['filter']
      self.label = value['label']
      self.default = value['default'] # Unknown type
      self
    end
  end

  # interface Message {
  #         /** Unique identifier for the message. */
  #         id: number;
  #         /** A format string for the message. Embedded variables have the form '{name}'.
  #             If variable name starts with an underscore character, the variable does not contain user data (PII) and can be safely used for telemetry purposes.
  #         */
  #         format: string;
  #         /** An object used as a dictionary for looking up the variables in the format string. */
  #         variables?: {
  #             [key: string]: string;
  #         };
  #         /** If true send to telemetry. */
  #         sendTelemetry?: boolean;
  #         /** If true show user. */
  #         showUser?: boolean;
  #         /** An optional url where additional information about this message can be found. */
  #         url?: string;
  #         /** An optional label that is presented to the user as the UI for opening the url. */
  #         urlLabel?: string;
  #     }
  class Message < DSPBase
    attr_accessor :id # type: number
    attr_accessor :format # type: string
    attr_accessor :variables # type: {
    #            [key: string]: string;
    #        }
    attr_accessor :sendTelemetry # type: boolean
    attr_accessor :showUser # type: boolean
    attr_accessor :url # type: string
    attr_accessor :urlLabel # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[variables sendTelemetry showUser url urlLabel]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.format = value['format']
      self.variables = value['variables'] # Unknown type
      self.sendTelemetry = value['sendTelemetry'] # Unknown type
      self.showUser = value['showUser'] # Unknown type
      self.url = value['url']
      self.urlLabel = value['urlLabel']
      self
    end
  end

  # interface Module {
  #         /** Unique identifier for the module. */
  #         id: number | string;
  #         /** A name of the module. */
  #         name: string;
  #         /** optional but recommended attributes.
  #             always try to use these first before introducing additional attributes.
  #             
  #             Logical full path to the module. The exact definition is implementation defined, but usually this would be a full path to the on-disk file for the module.
  #         */
  #         path?: string;
  #         /** True if the module is optimized. */
  #         isOptimized?: boolean;
  #         /** True if the module is considered 'user code' by a debugger that supports 'Just My Code'. */
  #         isUserCode?: boolean;
  #         /** Version of Module. */
  #         version?: string;
  #         /** User understandable description of if symbols were found for the module (ex: 'Symbols Loaded', 'Symbols not found', etc. */
  #         symbolStatus?: string;
  #         /** Logical full path to the symbol file. The exact definition is implementation defined. */
  #         symbolFilePath?: string;
  #         /** Module created or modified. */
  #         dateTimeStamp?: string;
  #         /** Address range covered by this module. */
  #         addressRange?: string;
  #     }
  class Module < DSPBase
    attr_accessor :id # type: number | string
    attr_accessor :name # type: string
    attr_accessor :path # type: string
    attr_accessor :isOptimized # type: boolean
    attr_accessor :isUserCode # type: boolean
    attr_accessor :version # type: string
    attr_accessor :symbolStatus # type: string
    attr_accessor :symbolFilePath # type: string
    attr_accessor :dateTimeStamp # type: string
    attr_accessor :addressRange # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[path isOptimized isUserCode version symbolStatus symbolFilePath dateTimeStamp addressRange]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id'] # Unknown type
      self.name = value['name']
      self.path = value['path']
      self.isOptimized = value['isOptimized'] # Unknown type
      self.isUserCode = value['isUserCode'] # Unknown type
      self.version = value['version']
      self.symbolStatus = value['symbolStatus']
      self.symbolFilePath = value['symbolFilePath']
      self.dateTimeStamp = value['dateTimeStamp']
      self.addressRange = value['addressRange']
      self
    end
  end

  # interface ColumnDescriptor {
  #         /** Name of the attribute rendered in this column. */
  #         attributeName: string;
  #         /** Header UI label of column. */
  #         label: string;
  #         /** Format to use for the rendered values in this column. TBD how the format strings looks like. */
  #         format?: string;
  #         /** Datatype of values in this column.  Defaults to 'string' if not specified. */
  #         type?: 'string' | 'number' | 'boolean' | 'unixTimestampUTC';
  #         /** Width of this column in characters (hint only). */
  #         width?: number;
  #     }
  class ColumnDescriptor < DSPBase
    attr_accessor :attributeName # type: string
    attr_accessor :label # type: string
    attr_accessor :format # type: string
    attr_accessor :type # type: string with value 'string' | 'number' | 'boolean' | 'unixTimestampUTC'
    attr_accessor :width # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[format type width]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.attributeName = value['attributeName']
      self.label = value['label']
      self.format = value['format']
      self.type = value['type'] # Unknown type
      self.width = value['width']
      self
    end
  end

  # interface ModulesViewDescriptor {
  #         columns: ColumnDescriptor[];
  #     }
  class ModulesViewDescriptor < DSPBase
    attr_accessor :columns # type: ColumnDescriptor[]

    def from_h!(value)
      value = {} if value.nil?
      self.columns = to_typed_aray(value['columns'], ColumnDescriptor)
      self
    end
  end

  # interface Thread {
  #         /** Unique identifier for the thread. */
  #         id: number;
  #         /** A name of the thread. */
  #         name: string;
  #     }
  class Thread < DSPBase
    attr_accessor :id # type: number
    attr_accessor :name # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.name = value['name']
      self
    end
  end

  # interface Source {
  #         /** The short name of the source. Every source returned from the debug adapter has a name. When sending a source to the debug adapter this name is optional. */
  #         name?: string;
  #         /** The path of the source to be shown in the UI. It is only used to locate and load the content of the source if no sourceReference is specified (or its value is 0). */
  #         path?: string;
  #         /** If sourceReference > 0 the contents of the source must be retrieved through the SourceRequest (even if a path is specified). A sourceReference is only valid for a session, so it must not be used to persist a source. */
  #         sourceReference?: number;
  #         /** An optional hint for how to present the source in the UI. A value of 'deemphasize' can be used to indicate that the source is not available or that it is skipped on stepping. */
  #         presentationHint?: 'normal' | 'emphasize' | 'deemphasize';
  #         /** The (optional) origin of this source: possible values 'internal module', 'inlined content from source map', etc. */
  #         origin?: string;
  #         /** An optional list of sources that are related to this source. These may be the source that generated this source. */
  #         sources?: Source[];
  #         /** Optional data that a debug adapter might want to loop through the client. The client should leave the data intact and persist it across sessions. The client should not interpret the data. */
  #         adapterData?: any;
  #         /** The checksums associated with this file. */
  #         checksums?: Checksum[];
  #     }
  class Source < DSPBase
    attr_accessor :name # type: string
    attr_accessor :path # type: string
    attr_accessor :sourceReference # type: number
    attr_accessor :presentationHint # type: string with value 'normal' | 'emphasize' | 'deemphasize'
    attr_accessor :origin # type: string
    attr_accessor :sources # type: Source[]
    attr_accessor :adapterData # type: any
    attr_accessor :checksums # type: Checksum[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[name path sourceReference presentationHint origin sources adapterData checksums]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.path = value['path']
      self.sourceReference = value['sourceReference']
      self.presentationHint = value['presentationHint'] # Unknown type
      self.origin = value['origin']
      self.sources = to_typed_aray(value['sources'], Source)
      self.adapterData = value['adapterData']
      self.checksums = to_typed_aray(value['checksums'], Checksum)
      self
    end
  end

  # interface StackFrame {
  #         /** An identifier for the stack frame. It must be unique across all threads. This id can be used to retrieve the scopes of the frame with the 'scopesRequest' or to restart the execution of a stackframe. */
  #         id: number;
  #         /** The name of the stack frame, typically a method name. */
  #         name: string;
  #         /** The optional source of the frame. */
  #         source?: Source;
  #         /** The line within the file of the frame. If source is null or doesn't exist, line is 0 and must be ignored. */
  #         line: number;
  #         /** The column within the line. If source is null or doesn't exist, column is 0 and must be ignored. */
  #         column: number;
  #         /** An optional end line of the range covered by the stack frame. */
  #         endLine?: number;
  #         /** An optional end column of the range covered by the stack frame. */
  #         endColumn?: number;
  #         /** Optional memory reference for the current instruction pointer in this frame. */
  #         instructionPointerReference?: string;
  #         /** The module associated with this frame, if any. */
  #         moduleId?: number | string;
  #         /** An optional hint for how to present this frame in the UI. A value of 'label' can be used to indicate that the frame is an artificial frame that is used as a visual label or separator. A value of 'subtle' can be used to change the appearance of a frame in a 'subtle' way. */
  #         presentationHint?: 'normal' | 'label' | 'subtle';
  #     }
  class StackFrame < DSPBase
    attr_accessor :id # type: number
    attr_accessor :name # type: string
    attr_accessor :source # type: Source
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endColumn # type: number
    attr_accessor :instructionPointerReference # type: string
    attr_accessor :moduleId # type: number | string
    attr_accessor :presentationHint # type: string with value 'normal' | 'label' | 'subtle'

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[source endLine endColumn instructionPointerReference moduleId presentationHint]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.name = value['name']
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.line = value['line']
      self.column = value['column']
      self.endLine = value['endLine']
      self.endColumn = value['endColumn']
      self.instructionPointerReference = value['instructionPointerReference']
      self.moduleId = value['moduleId'] # Unknown type
      self.presentationHint = value['presentationHint'] # Unknown type
      self
    end
  end

  # interface Scope {
  #         /** Name of the scope such as 'Arguments', 'Locals', or 'Registers'. This string is shown in the UI as is and can be translated. */
  #         name: string;
  #         /** An optional hint for how to present this scope in the UI. If this attribute is missing, the scope is shown with a generic UI.
  #             Values:
  #             'arguments': Scope contains method arguments.
  #             'locals': Scope contains local variables.
  #             'registers': Scope contains registers. Only a single 'registers' scope should be returned from a 'scopes' request.
  #             etc.
  #         */
  #         presentationHint?: string;
  #         /** The variables of this scope can be retrieved by passing the value of variablesReference to the VariablesRequest. */
  #         variablesReference: number;
  #         /** The number of named variables in this scope.
  #             The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #         */
  #         namedVariables?: number;
  #         /** The number of indexed variables in this scope.
  #             The client can use this optional information to present the variables in a paged UI and fetch them in chunks.
  #         */
  #         indexedVariables?: number;
  #         /** If true, the number of variables in this scope is large or expensive to retrieve. */
  #         expensive: boolean;
  #         /** Optional source for this scope. */
  #         source?: Source;
  #         /** Optional start line of the range covered by this scope. */
  #         line?: number;
  #         /** Optional start column of the range covered by this scope. */
  #         column?: number;
  #         /** Optional end line of the range covered by this scope. */
  #         endLine?: number;
  #         /** Optional end column of the range covered by this scope. */
  #         endColumn?: number;
  #     }
  class Scope < DSPBase
    attr_accessor :name # type: string
    attr_accessor :presentationHint # type: string
    attr_accessor :variablesReference # type: number
    attr_accessor :namedVariables # type: number
    attr_accessor :indexedVariables # type: number
    attr_accessor :expensive # type: boolean
    attr_accessor :source # type: Source
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endColumn # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[presentationHint namedVariables indexedVariables source line column endLine endColumn]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.presentationHint = value['presentationHint']
      self.variablesReference = value['variablesReference']
      self.namedVariables = value['namedVariables']
      self.indexedVariables = value['indexedVariables']
      self.expensive = value['expensive'] # Unknown type
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.line = value['line']
      self.column = value['column']
      self.endLine = value['endLine']
      self.endColumn = value['endColumn']
      self
    end
  end

  # interface Variable {
  #         /** The variable's name. */
  #         name: string;
  #         /** The variable's value. This can be a multi-line text, e.g. for a function the body of a function. */
  #         value: string;
  #         /** The type of the variable's value. Typically shown in the UI when hovering over the value. */
  #         type?: string;
  #         /** Properties of a variable that can be used to determine how to render the variable in the UI. */
  #         presentationHint?: VariablePresentationHint;
  #         /** Optional evaluatable name of this variable which can be passed to the 'EvaluateRequest' to fetch the variable's value. */
  #         evaluateName?: string;
  #         /** If variablesReference is > 0, the variable is structured and its children can be retrieved by passing variablesReference to the VariablesRequest. */
  #         variablesReference: number;
  #         /** The number of named child variables.
  #             The client can use this optional information to present the children in a paged UI and fetch them in chunks.
  #         */
  #         namedVariables?: number;
  #         /** The number of indexed child variables.
  #             The client can use this optional information to present the children in a paged UI and fetch them in chunks.
  #         */
  #         indexedVariables?: number;
  #         /** Optional memory reference for the variable if the variable represents executable code, such as a function pointer. */
  #         memoryReference?: string;
  #     }
  class Variable < DSPBase
    attr_accessor :name # type: string
    attr_accessor :value # type: string
    attr_accessor :type # type: string
    attr_accessor :presentationHint # type: VariablePresentationHint
    attr_accessor :evaluateName # type: string
    attr_accessor :variablesReference # type: number
    attr_accessor :namedVariables # type: number
    attr_accessor :indexedVariables # type: number
    attr_accessor :memoryReference # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[type presentationHint evaluateName namedVariables indexedVariables memoryReference]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.value = value['value']
      self.type = value['type']
      self.presentationHint = VariablePresentationHint.new(value['presentationHint']) unless value['presentationHint'].nil?
      self.evaluateName = value['evaluateName']
      self.variablesReference = value['variablesReference']
      self.namedVariables = value['namedVariables']
      self.indexedVariables = value['indexedVariables']
      self.memoryReference = value['memoryReference']
      self
    end
  end

  # interface VariablePresentationHint {
  #         /** The kind of variable. Before introducing additional values, try to use the listed values.
  #             Values:
  #             'property': Indicates that the object is a property.
  #             'method': Indicates that the object is a method.
  #             'class': Indicates that the object is a class.
  #             'data': Indicates that the object is data.
  #             'event': Indicates that the object is an event.
  #             'baseClass': Indicates that the object is a base class.
  #             'innerClass': Indicates that the object is an inner class.
  #             'interface': Indicates that the object is an interface.
  #             'mostDerivedClass': Indicates that the object is the most derived class.
  #             'virtual': Indicates that the object is virtual, that means it is a synthetic object introduced by the adapter for rendering purposes, e.g. an index range for large arrays.
  #             'dataBreakpoint': Indicates that a data breakpoint is registered for the object.
  #             etc.
  #         */
  #         kind?: string;
  #         /** Set of attributes represented as an array of strings. Before introducing additional values, try to use the listed values.
  #             Values:
  #             'static': Indicates that the object is static.
  #             'constant': Indicates that the object is a constant.
  #             'readOnly': Indicates that the object is read only.
  #             'rawString': Indicates that the object is a raw string.
  #             'hasObjectId': Indicates that the object can have an Object ID created for it.
  #             'canHaveObjectId': Indicates that the object has an Object ID associated with it.
  #             'hasSideEffects': Indicates that the evaluation had side effects.
  #             etc.
  #         */
  #         attributes?: string[];
  #         /** Visibility of variable. Before introducing additional values, try to use the listed values.
  #             Values: 'public', 'private', 'protected', 'internal', 'final', etc.
  #         */
  #         visibility?: string;
  #     }
  class VariablePresentationHint < DSPBase
    attr_accessor :kind # type: string
    attr_accessor :attributes # type: string[]
    attr_accessor :visibility # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind attributes visibility]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind']
      self.attributes = value['attributes'].map { |val| val } unless value['attributes'].nil?
      self.visibility = value['visibility']
      self
    end
  end

  # interface SourceBreakpoint {
  #         /** The source line of the breakpoint or logpoint. */
  #         line: number;
  #         /** An optional source column of the breakpoint. */
  #         column?: number;
  #         /** An optional expression for conditional breakpoints. */
  #         condition?: string;
  #         /** An optional expression that controls how many hits of the breakpoint are ignored. The backend is expected to interpret the expression as needed. */
  #         hitCondition?: string;
  #         /** If this attribute exists and is non-empty, the backend must not 'break' (stop) but log the message instead. Expressions within {} are interpolated. */
  #         logMessage?: string;
  #     }
  class SourceBreakpoint < DSPBase
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :condition # type: string
    attr_accessor :hitCondition # type: string
    attr_accessor :logMessage # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[column condition hitCondition logMessage]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.line = value['line']
      self.column = value['column']
      self.condition = value['condition']
      self.hitCondition = value['hitCondition']
      self.logMessage = value['logMessage']
      self
    end
  end

  # interface FunctionBreakpoint {
  #         /** The name of the function. */
  #         name: string;
  #         /** An optional expression for conditional breakpoints. */
  #         condition?: string;
  #         /** An optional expression that controls how many hits of the breakpoint are ignored. The backend is expected to interpret the expression as needed. */
  #         hitCondition?: string;
  #     }
  class FunctionBreakpoint < DSPBase
    attr_accessor :name # type: string
    attr_accessor :condition # type: string
    attr_accessor :hitCondition # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[condition hitCondition]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.condition = value['condition']
      self.hitCondition = value['hitCondition']
      self
    end
  end

  # interface DataBreakpoint {
  #         /** An id representing the data. This id is returned from the dataBreakpointInfo request. */
  #         dataId: string;
  #         /** The access type of the data. */
  #         accessType?: DataBreakpointAccessType;
  #         /** An optional expression for conditional breakpoints. */
  #         condition?: string;
  #         /** An optional expression that controls how many hits of the breakpoint are ignored. The backend is expected to interpret the expression as needed. */
  #         hitCondition?: string;
  #     }
  class DataBreakpoint < DSPBase
    attr_accessor :dataId # type: string
    attr_accessor :accessType # type: DataBreakpointAccessType
    attr_accessor :condition # type: string
    attr_accessor :hitCondition # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[accessType condition hitCondition]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dataId = value['dataId']
      self.accessType = value['accessType'] # Unknown type
      self.condition = value['condition']
      self.hitCondition = value['hitCondition']
      self
    end
  end

  # interface Breakpoint {
  #         /** An optional identifier for the breakpoint. It is needed if breakpoint events are used to update or remove breakpoints. */
  #         id?: number;
  #         /** If true breakpoint could be set (but not necessarily at the desired location). */
  #         verified: boolean;
  #         /** An optional message about the state of the breakpoint. This is shown to the user and can be used to explain why a breakpoint could not be verified. */
  #         message?: string;
  #         /** The source where the breakpoint is located. */
  #         source?: Source;
  #         /** The start line of the actual range covered by the breakpoint. */
  #         line?: number;
  #         /** An optional start column of the actual range covered by the breakpoint. */
  #         column?: number;
  #         /** An optional end line of the actual range covered by the breakpoint. */
  #         endLine?: number;
  #         /** An optional end column of the actual range covered by the breakpoint. If no end line is given, then the end column is assumed to be in the start line. */
  #         endColumn?: number;
  #     }
  class Breakpoint < DSPBase
    attr_accessor :id # type: number
    attr_accessor :verified # type: boolean
    attr_accessor :message # type: string
    attr_accessor :source # type: Source
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endColumn # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[id message source line column endLine endColumn]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.verified = value['verified'] # Unknown type
      self.message = value['message']
      self.source = Source.new(value['source']) unless value['source'].nil?
      self.line = value['line']
      self.column = value['column']
      self.endLine = value['endLine']
      self.endColumn = value['endColumn']
      self
    end
  end

  # interface StepInTarget {
  #         /** Unique identifier for a stepIn target. */
  #         id: number;
  #         /** The name of the stepIn target (shown in the UI). */
  #         label: string;
  #     }
  class StepInTarget < DSPBase
    attr_accessor :id # type: number
    attr_accessor :label # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.label = value['label']
      self
    end
  end

  # interface GotoTarget {
  #         /** Unique identifier for a goto target. This is used in the goto request. */
  #         id: number;
  #         /** The name of the goto target (shown in the UI). */
  #         label: string;
  #         /** The line of the goto target. */
  #         line: number;
  #         /** An optional column of the goto target. */
  #         column?: number;
  #         /** An optional end line of the range covered by the goto target. */
  #         endLine?: number;
  #         /** An optional end column of the range covered by the goto target. */
  #         endColumn?: number;
  #         /** Optional memory reference for the instruction pointer value represented by this target. */
  #         instructionPointerReference?: string;
  #     }
  class GotoTarget < DSPBase
    attr_accessor :id # type: number
    attr_accessor :label # type: string
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endColumn # type: number
    attr_accessor :instructionPointerReference # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[column endLine endColumn instructionPointerReference]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.label = value['label']
      self.line = value['line']
      self.column = value['column']
      self.endLine = value['endLine']
      self.endColumn = value['endColumn']
      self.instructionPointerReference = value['instructionPointerReference']
      self
    end
  end

  # interface CompletionItem {
  #         /** The label of this completion item. By default this is also the text that is inserted when selecting this completion. */
  #         label: string;
  #         /** If text is not falsy then it is inserted instead of the label. */
  #         text?: string;
  #         /** The item's type. Typically the client uses this information to render the item in the UI with an icon. */
  #         type?: CompletionItemType;
  #         /** This value determines the location (in the CompletionsRequest's 'text' attribute) where the completion text is added.
  #             If missing the text is added at the location specified by the CompletionsRequest's 'column' attribute.
  #         */
  #         start?: number;
  #         /** This value determines how many characters are overwritten by the completion text.
  #             If missing the value 0 is assumed which results in the completion text being inserted.
  #         */
  #         length?: number;
  #     }
  class CompletionItem < DSPBase
    attr_accessor :label # type: string
    attr_accessor :text # type: string
    attr_accessor :type # type: CompletionItemType
    attr_accessor :start # type: number
    attr_accessor :length # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[text type start length]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label']
      self.text = value['text']
      self.type = value['type'] # Unknown type
      self.start = value['start']
      self.length = value['length']
      self
    end
  end

  # interface Checksum {
  #         /** The algorithm used to calculate this checksum. */
  #         algorithm: ChecksumAlgorithm;
  #         /** Value of the checksum. */
  #         checksum: string;
  #     }
  class Checksum < DSPBase
    attr_accessor :algorithm # type: ChecksumAlgorithm
    attr_accessor :checksum # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.algorithm = value['algorithm'] # Unknown type
      self.checksum = value['checksum']
      self
    end
  end

  # interface ValueFormat {
  #         /** Display the value in hex. */
  #         hex?: boolean;
  #     }
  class ValueFormat < DSPBase
    attr_accessor :hex # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[hex]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.hex = value['hex'] # Unknown type
      self
    end
  end

  # interface StackFrameFormat extends ValueFormat {
  #         /** Displays parameters for the stack frame. */
  #         parameters?: boolean;
  #         /** Displays the types of parameters for the stack frame. */
  #         parameterTypes?: boolean;
  #         /** Displays the names of parameters for the stack frame. */
  #         parameterNames?: boolean;
  #         /** Displays the values of parameters for the stack frame. */
  #         parameterValues?: boolean;
  #         /** Displays the line number of the stack frame. */
  #         line?: boolean;
  #         /** Displays the module of the stack frame. */
  #         module?: boolean;
  #         /** Includes all stack frames, including those the debug adapter might otherwise hide. */
  #         includeAll?: boolean;
  #     }
  class StackFrameFormat < DSPBase
    attr_accessor :parameters # type: boolean
    attr_accessor :parameterTypes # type: boolean
    attr_accessor :parameterNames # type: boolean
    attr_accessor :parameterValues # type: boolean
    attr_accessor :line # type: boolean
    attr_accessor :module # type: boolean
    attr_accessor :includeAll # type: boolean
    attr_accessor :hex # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[parameters parameterTypes parameterNames parameterValues line module includeAll hex]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.parameters = value['parameters'] # Unknown type
      self.parameterTypes = value['parameterTypes'] # Unknown type
      self.parameterNames = value['parameterNames'] # Unknown type
      self.parameterValues = value['parameterValues'] # Unknown type
      self.line = value['line'] # Unknown type
      self.module = value['module'] # Unknown type
      self.includeAll = value['includeAll'] # Unknown type
      self.hex = value['hex'] # Unknown type
      self
    end
  end

  # interface ExceptionOptions {
  #         /** A path that selects a single or multiple exceptions in a tree. If 'path' is missing, the whole tree is selected. By convention the first segment of the path is a category that is used to group exceptions in the UI. */
  #         path?: ExceptionPathSegment[];
  #         /** Condition when a thrown exception should result in a break. */
  #         breakMode: ExceptionBreakMode;
  #     }
  class ExceptionOptions < DSPBase
    attr_accessor :path # type: ExceptionPathSegment[]
    attr_accessor :breakMode # type: ExceptionBreakMode

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[path]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.path = to_typed_aray(value['path'], ExceptionPathSegment)
      self.breakMode = value['breakMode'] # Unknown type
      self
    end
  end

  # interface ExceptionPathSegment {
  #         /** If false or missing this segment matches the names provided, otherwise it matches anything except the names provided. */
  #         negate?: boolean;
  #         /** Depending on the value of 'negate' the names that should match or not match. */
  #         names: string[];
  #     }
  class ExceptionPathSegment < DSPBase
    attr_accessor :negate # type: boolean
    attr_accessor :names # type: string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[negate]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.negate = value['negate'] # Unknown type
      self.names = value['names'].map { |val| val } unless value['names'].nil?
      self
    end
  end

  # interface ExceptionDetails {
  #         /** Message contained in the exception. */
  #         message?: string;
  #         /** Short type name of the exception object. */
  #         typeName?: string;
  #         /** Fully-qualified type name of the exception object. */
  #         fullTypeName?: string;
  #         /** Optional expression that can be evaluated in the current scope to obtain the exception object. */
  #         evaluateName?: string;
  #         /** Stack trace at the time the exception was thrown. */
  #         stackTrace?: string;
  #         /** Details of the exception contained by this exception, if any. */
  #         innerException?: ExceptionDetails[];
  #     }
  class ExceptionDetails < DSPBase
    attr_accessor :message # type: string
    attr_accessor :typeName # type: string
    attr_accessor :fullTypeName # type: string
    attr_accessor :evaluateName # type: string
    attr_accessor :stackTrace # type: string
    attr_accessor :innerException # type: ExceptionDetails[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[message typeName fullTypeName evaluateName stackTrace innerException]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.message = value['message']
      self.typeName = value['typeName']
      self.fullTypeName = value['fullTypeName']
      self.evaluateName = value['evaluateName']
      self.stackTrace = value['stackTrace']
      self.innerException = to_typed_aray(value['innerException'], ExceptionDetails)
      self
    end
  end

  # interface DisassembledInstruction {
  #         /** The address of the instruction. Treated as a hex value if prefixed with '0x', or as a decimal value otherwise. */
  #         address: string;
  #         /** Optional raw bytes representing the instruction and its operands, in an implementation-defined format. */
  #         instructionBytes?: string;
  #         /** Text representing the instruction and its operands, in an implementation-defined format. */
  #         instruction: string;
  #         /** Name of the symbol that correponds with the location of this instruction, if any. */
  #         symbol?: string;
  #         /** Source location that corresponds to this instruction, if any. Should always be set (if available) on the first instruction returned, but can be omitted afterwards if this instruction maps to the same source file as the previous instruction. */
  #         location?: Source;
  #         /** The line within the source location that corresponds to this instruction, if any. */
  #         line?: number;
  #         /** The column within the line that corresponds to this instruction, if any. */
  #         column?: number;
  #         /** The end line of the range that corresponds to this instruction, if any. */
  #         endLine?: number;
  #         /** The end column of the range that corresponds to this instruction, if any. */
  #         endColumn?: number;
  #     }
  class DisassembledInstruction < DSPBase
    attr_accessor :address # type: string
    attr_accessor :instructionBytes # type: string
    attr_accessor :instruction # type: string
    attr_accessor :symbol # type: string
    attr_accessor :location # type: Source
    attr_accessor :line # type: number
    attr_accessor :column # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endColumn # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[instructionBytes symbol location line column endLine endColumn]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.address = value['address']
      self.instructionBytes = value['instructionBytes']
      self.instruction = value['instruction']
      self.symbol = value['symbol']
      self.location = Source.new(value['location']) unless value['location'].nil?
      self.line = value['line']
      self.column = value['column']
      self.endLine = value['endLine']
      self.endColumn = value['endColumn']
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Layout/TrailingWhitespace

# frozen_string_literal: true

# Custom LSP Messages
# rubocop:disable Naming/MethodName

module LSP
  # export interface PuppetVersionDetails {
  #   puppetVersion: string;
  #   facterVersion: string;
  #   languageServerVersion: string;
  #   factsLoaded: boolean;
  #   functionsLoaded: boolean;
  #   typesLoaded: boolean;
  #   classesLoaded: boolean;
  # }
  class PuppetVersion < LSPBase
    attr_accessor :puppetVersion, :facterVersion, :languageServerVersion, :factsLoaded, :functionsLoaded, :typesLoaded, :classesLoaded # type: string # type: string # type: string # type: boolean # type: boolean # type: boolean # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.puppetVersion = value['puppetVersion']
      self.facterVersion = value['facterVersion']
      self.languageServerVersion = value['languageServerVersion']
      self.factsLoaded = value['factsLoaded']
      self.functionsLoaded = value['functionsLoaded']
      self.typesLoaded = value['typesLoaded']
      self.classesLoaded = value['classesLoaded']
      self
    end
  end

  # export interface GetPuppetFactResponse {
  #   data: string;
  #   error: string;
  # }
  class PuppetFactResponse < LSPBase
    attr_accessor :facts, :error # type: string # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.facts = value['facts']
      self.error = value['error']
      self
    end
  end

  # export interface GetPuppetResourceResponse {
  #   data: string;
  #   error: string;
  # }
  class PuppetResourceResponse < LSPBase
    attr_accessor :data, :error # type: string # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.data = value['data']
      self.error = value['error']
      self
    end
  end

  # export interface PuppetNodeGraphResponse {
  #   dotContent: string;
  #   data: string;
  # }
  class PuppetNodeGraphResponse < LSPBase
    attr_accessor :vertices, :edges, :error # type: string # type: string # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.vertices = value['vertices']
      self.edges = value['edges']
      self.error = value['error']
      self
    end
  end

  # export interface PuppetfileDependencyResponse {
  #   dotContent: string;
  #   data: string;
  # }
  class PuppetfileDependencyResponse < LSPBase
    attr_accessor :dependencies, :error # type: string[] # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dependencies = value['dependencies']
      self.error = value['error']
      self
    end
  end

  # export interface CompileNodeGraphResponse {
  #   dotContent: string;
  #   data: string;
  # }
  class CompileNodeGraphResponse < LSPBase
    attr_accessor :dotContent, :error # type: string # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[error]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dotContent = value['dotContent']
      self.error = value['error']
      self
    end
  end

  # export interface PuppetFixDiagnosticErrorsRequestParams {
  #   documentUri: string;
  #   alwaysReturnContent: boolean;
  # }
  class PuppetFixDiagnosticErrorsRequest < LSPBase
    attr_accessor :documentUri, :alwaysReturnContent # type: string # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.documentUri = value['documentUri']
      self.alwaysReturnContent = value['alwaysReturnContent']
      self
    end
  end

  # export interface PuppetFixDiagnosticErrorsResponse {
  #   documentUri: string;
  #   fixesApplied: number;
  #   newContent?: string;
  # }
  class PuppetFixDiagnosticErrorsResponse < LSPBase
    attr_accessor :documentUri, :fixesApplied, :newContent # type: string # type: number # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[newContent]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentUri = value['documentUri']
      self.fixesApplied = value['fixesApplied']
      self.newContent = value['newContent']
      self
    end
  end
end
# rubocop:enable Naming/MethodName

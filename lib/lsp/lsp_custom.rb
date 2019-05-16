# frozen_string_literal: true

# Custom LSP Messages

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
    attr_accessor :puppetVersion # type: string
    attr_accessor :facterVersion # type: string
    attr_accessor :languageServerVersion # type: string
    attr_accessor :factsLoaded # type: boolean
    attr_accessor :functionsLoaded # type: boolean
    attr_accessor :typesLoaded # type: boolean
    attr_accessor :classesLoaded # type: boolean

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

  # export interface GetPuppetResourceResponse {
  #   data: string;
  #   error: string;
  # }
  class PuppetResourceResponse < LSPBase
    attr_accessor :data # type: string
    attr_accessor :error # type: string

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

  # export interface CompileNodeGraphResponse {
  #   dotContent: string;
  #   data: string;
  # }
  class CompileNodeGraphResponse < LSPBase
    attr_accessor :dotContent # type: string
    attr_accessor :error # type: string

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
    attr_accessor :documentUri # type: string
    attr_accessor :alwaysReturnContent # type: boolean

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
    attr_accessor :documentUri # type: string
    attr_accessor :fixesApplied # type: number
    attr_accessor :newContent # type: string

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

# frozen_string_literal: true

require 'molinillo'

module PuppetfileResolver
  class ResolutionResult
    attr_reader :dependency_graph

    def initialize(dependency_graph, puppetfile_document)
      raise "Expected Molinillo::DependencyGraph but got #{dependency_graph.class}" unless dependency_graph.is_a?(Molinillo::DependencyGraph)
      @dependency_graph = dependency_graph
      @puppetfile_document = puppetfile_document
    end

    def specifications
      # Note - Later rubies have `.transform_values` however we support old Ruby versions
      result = {}
      @dependency_graph.vertices.each { |key, vertex| result[key] = vertex.payload }
      result
    end

    def to_dot
      @dependency_graph.to_dot
    end

    def validation_errors
      @puppetfile_document.resolution_validation_errors(self)
    end
  end
end

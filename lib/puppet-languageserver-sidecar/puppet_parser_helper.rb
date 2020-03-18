# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module PuppetParserHelper
    def self.compile_node_graph(content)
      result = PuppetLanguageServerSidecar::Protocol::Graph.new

      begin
        node_graph = compile_to_pretty_relationship_graph(content)
        if node_graph.vertices.count.zero?
          result.set_error('There were no resources created in the node graph. Is there an include statement missing?')
          return result
        end

        result.vertices = []
        result.edges = []

        node_graph.vertices.each do |vertex|
          # TODO: more?
          result.vertices << { label: vertex.to_s }
        end

        node_graph.edges.each do |edge|
          # TODO: more?
          result.edges << { source: edge.source.to_s, target: edge.target.to_s }
        end
      rescue StandardError => e
        result.set_error("Error while parsing the file. #{e}")
      rescue LoadError => e
        result.set_error("Load error while parsing the file. #{e}")
      end

      result
    end

    # Reference - https://github.com/puppetlabs/puppet/blob/master/spec/lib/puppet_spec/compiler.rb
    def self.compile_to_catalog(string, node = Puppet::Node.new('test'))
      Puppet[:code] = string
      # see lib/puppet/indirector/catalog/compiler.rb#filter
      Puppet::Parser::Compiler.compile(node).filter(&:virtual?)
    end

    def self.compile_to_ral(manifest, node = Puppet::Node.new('test'))
      # Add the node facts if they don't already exist
      node.merge(Facter.to_hash) if node.facts.nil?

      catalog = compile_to_catalog(manifest, node)
      ral = catalog.to_ral
      ral.finalize
      ral
    end

    def self.compile_to_relationship_graph(manifest, prioritizer = Puppet::Graph::SequentialPrioritizer.new)
      ral = compile_to_ral(manifest)
      graph = Puppet::Graph::RelationshipGraph.new(prioritizer)
      graph.populate_from(ral)
      graph
    end

    def self.compile_to_pretty_relationship_graph(manifest, prioritizer = Puppet::Graph::SequentialPrioritizer.new)
      graph = compile_to_relationship_graph(manifest, prioritizer)

      # Remove vertexes which just clutter the graph

      # Remove all of the Puppet::Type::Whit nodes.  This is an internal only class
      list = graph.vertices.select { |node| node.is_a?(Puppet::Type::Whit) }
      list.each { |node| graph.remove_vertex!(node) }

      # Remove all of the Puppet::Type::Schedule nodes
      list = graph.vertices.select { |node| node.is_a?(Puppet::Type::Schedule) }
      list.each { |node| graph.remove_vertex!(node) }

      # Remove all of the Puppet::Type::Filebucket nodes
      list = graph.vertices.select { |node| node.is_a?(Puppet::Type::Filebucket) }
      list.each { |node| graph.remove_vertex!(node) }

      graph
    end
  end
end

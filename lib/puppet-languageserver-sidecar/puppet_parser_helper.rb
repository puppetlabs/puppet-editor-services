# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module PuppetParserHelper
    def self.compile_node_graph(content)
      result = PuppetLanguageServerSidecar::Protocol::NodeGraph.new

      begin
        # The fontsize is inserted in the puppet code.  Need to remove it so the client can render appropriately.  Need to
        # set it to blank.  The graph label is set to editorservices so that we can do text replacement client side to inject the
        # appropriate styling.
        options = {
          'fontsize' => '""',
          'name'     => 'editorservices'
        }
        node_graph = compile_to_pretty_relationship_graph(content)
        if node_graph.vertices.count.zero?
          result.set_error('There were no resources created in the node graph. Is there an include statement missing?')
        else
          result.dot_content = node_graph.to_dot(options)
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

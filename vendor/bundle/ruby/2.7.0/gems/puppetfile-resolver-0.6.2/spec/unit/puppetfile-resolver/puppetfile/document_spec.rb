require 'spec_helper'

require 'puppetfile-resolver/models'
require 'puppetfile-resolver/resolution_result'
require 'puppetfile-resolver/puppetfile'

describe 'PuppetfileResolver::Puppetfile::Document' do
  let(:puppetfile_content) { 'puppetfile' }
  let(:subject) { PuppetfileResolver::Puppetfile::Document.new(puppetfile_content) }

  describe "Document Validation" do
    context 'Given an empty document' do
      before(:each) do
        subject.clear_modules
      end

      it 'should be valid' do
        expect(subject.valid?).to eq(true)
      end

      it 'should have no validation errors' do
        expect(subject.validation_errors).to eq([])
      end
    end

    context 'Given a document with valid modules' do
      let(:module1) { PuppetfileResolver::Puppetfile::LocalModule.new('foo') }
      let(:module2) { PuppetfileResolver::Puppetfile::LocalModule.new('bar') }
      let(:module3) { PuppetfileResolver::Puppetfile::LocalModule.new('baz') }

      before(:each) do
        subject.clear_modules
        subject.add_module(module1)
        subject.add_module(module2)
        subject.add_module(module3)
      end

      it 'should be valid' do
        expect(subject.valid?).to eq(true)
      end

      it 'should have no validation errors' do
        expect(subject.validation_errors).to eq([])
      end
    end

    context 'Given a document with an invalid module' do
      let(:invalid_module) do
        PuppetfileResolver::Puppetfile::InvalidModule.new('foo-invalid').tap { |m| m.reason = 'MockReason' }
      end

      before(:each) do
        subject.clear_modules
        subject.add_module(invalid_module)
      end

      it 'should not be valid' do
        expect(subject.valid?).to eq(false)
      end

      it 'should have a validation error' do
        expect(subject.validation_errors.count).to eq (1)
        expect(subject.validation_errors[0]).to be_a(PuppetfileResolver::Puppetfile::DocumentInvalidModuleError)
        expect(subject.validation_errors[0]).to have_attributes(
          :message => 'MockReason',
          :puppet_module => invalid_module
        )
      end
    end

    context 'Given a document with duplicate modules' do
      let(:module1) { PuppetfileResolver::Puppetfile::LocalModule.new('foo') }
      let(:module2) { PuppetfileResolver::Puppetfile::LocalModule.new('foo') }
      let(:module3) { PuppetfileResolver::Puppetfile::LocalModule.new('foo') }
      let(:module4) { PuppetfileResolver::Puppetfile::LocalModule.new('bar') }
      let(:module5) { PuppetfileResolver::Puppetfile::LocalModule.new('bar') }
      let(:module6) { PuppetfileResolver::Puppetfile::LocalModule.new('baz') }

      before(:each) do
        subject.clear_modules
        subject.add_module(module1)
        subject.add_module(module2)
        subject.add_module(module3)
        subject.add_module(module4)
        subject.add_module(module5)
        subject.add_module(module6)
      end

      it 'should not be valid' do
        expect(subject.valid?).to eq(false)
      end

      it 'should have validation errors' do
        expect(subject.validation_errors.count).to eq (2)
        # Duplication foo module
        err = subject.validation_errors[0]
        expect(err).to be_a(PuppetfileResolver::Puppetfile::DocumentDuplicateModuleError)
        expect(err).to have_attributes(
          :message => /foo/,
          :puppet_module => module1,
          :duplicates => [module2, module3]
        )
        # Duplicate bar module
        err = subject.validation_errors[1]
        expect(err).to be_a(PuppetfileResolver::Puppetfile::DocumentDuplicateModuleError)
        expect(err).to have_attributes(
          :message => /bar/,
          :puppet_module => module4,
          :duplicates => [module5]
        )
      end
    end
  end

  describe ".resolution_validation_errors" do
    # Array of modules to add to the document
    let(:document_fixtures) { [] }
    let(:resolution_graph) { Molinillo::DependencyGraph.new }
    let(:resolution_result) { PuppetfileResolver::ResolutionResult.new(resolution_graph, subject) }
    let(:resolution_specifications) { [] }
    let(:resolution_dependencies) { [] }

    before(:each) do
      # Generate the Puppetfile document
      subject.clear_modules
      @document_modules = document_fixtures.map do |doc_mod|
        mod = doc_mod[:class].new(doc_mod[:name])
        mod.version = doc_mod[:version]
        mod.resolver_flags = doc_mod[:flags] unless doc_mod[:flags].nil?
        subject.add_module(mod)
        mod
      end

      # Generate the Dependency Graph
      @module_specifications = {}
      # Create all of the specifications
      resolution_specifications.each do |res_spec|
        res_spec[:class] = PuppetfileResolver::Models::ModuleSpecification if res_spec[:class].nil?
        @module_specifications[res_spec[:name]] = res_spec[:class].new(name: res_spec[:name], origin: res_spec[:origin], metadata: {}, version: res_spec[:version])
      end
      # Create all of the vertexes in the graph
      @module_specifications.each { |name, spec| resolution_graph.add_vertex(name, spec, false) }
      # Create all of the edges in the graph
      resolution_dependencies.each do |dep|
        dep[:class] = PuppetfileResolver::Models::ModuleDependency if dep[:class].nil?
        mod_dep = dep[:class].new(name: dep[:destination], version_requirement: dep[:version_requirement])
        resolution_graph.add_edge(
          resolution_graph.vertex_named(dep[:origin]),
          resolution_graph.vertex_named(dep[:destination]),
          mod_dep
        )
      end
    end

    context 'Given an invalid document' do
      before(:each) do
        allow(subject).to receive(:valid?).and_return(false)
      end

      it 'should raise' do
        expect{ subject.resolution_validation_errors(resolution_result) }.to raise_error(/invalid document/)
      end
    end

    context 'Given a valid resolution' do
      let(:document_fixtures) do
        [
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'foo' },
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'bar' }
        ]
      end
      let(:resolution_specifications) do
        [
          { name: 'foo', origin: :local, version: '1.0.0' },
          { name: 'bar', origin: :local, version: '1.0.0' }
        ]
      end
      let(:resolution_dependencies) do
        [
          { origin: 'foo', destination: 'bar', version_requirement: '>= 0' },
        ]
      end
      it 'should return no errors' do
        expect(subject.resolution_validation_errors(resolution_result)).to be_empty
      end
    end

    context 'Given a document with :latest' do
      let(:document_fixtures) do
        [
          { class: PuppetfileResolver::Puppetfile::ForgeModule, name: 'foo', version: :latest }
        ]
      end
      let(:resolution_specifications) do
        [
          { name: 'foo', origin: :forge, version: '1.0.0' }
        ]
      end

      it 'should return a DocumentLatestVersionError' do
        errors = subject.resolution_validation_errors(resolution_result)
        expect(errors.count).to eq(1)
        error = errors[0]
        expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentLatestVersionError)
        expect(error).to have_attributes(
          message: /foo/,
          module_specification: @module_specifications['foo'],
          puppet_module: @document_modules[0]
        )
      end

      context 'and using the DISABLE_LATEST_VALIDATION_FLAG flag' do
        let(:document_fixtures) do
          [
            { class: PuppetfileResolver::Puppetfile::ForgeModule, name: 'foo', version: :latest, flags: [PuppetfileResolver::Puppetfile::DISABLE_LATEST_VALIDATION_FLAG] }
          ]
        end

        it 'should not return a DocumentLatestVersionError' do
          errors = subject.resolution_validation_errors(resolution_result)
          expect(errors.count).to eq(0)
        end
      end
    end

    context 'Given a document with a missing module' do
      let(:document_fixtures) do
        [
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'foo', version: :latest }
        ]
      end
      let(:resolution_specifications) do
        [
          { class: PuppetfileResolver::Models::MissingModuleSpecification, name: 'foo' }
        ]
      end

      it 'should return a DocumentMissingModuleError' do
        errors = subject.resolution_validation_errors(resolution_result)
        expect(errors.count).to eq(1)
        error = errors[0]
        expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentMissingModuleError)
        expect(error).to have_attributes(
          message: /foo/,
          module_specification: @module_specifications['foo'],
          puppet_module: @document_modules[0]
        )
      end
    end

    context 'Given a document with missing module dependencies' do
      # We setup a Puppetfile that looks like
      # ```
      # mod 'foo', :local => true
      # mod 'baz', :local => true
      # mod 'waldo', :local => true
      # ```
      let(:document_fixtures) do
        [
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'foo',   version: '1.0.0' },
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'baz',   version: '1.0.0' },
          { class: PuppetfileResolver::Puppetfile::LocalModule, name: 'waldo', version: '1.0.0' },
        ]
      end
      # We then setup a resolution graph that looks like
      #
      #   foo --> bar --> baz --> qux
      #            waldo --^
      #
      # Where foo depends on bar, which depends on baz, which depends on qux. And
      # waldo depends on baz, which depends on qux
      #
      # Due to the puppetfile and dependency graph:
      # - foo will be missing bar and qux
      # - baz will be missing qux
      # - waldo will be missing qux
      #
      # This is to test for transitive dependencies, not just an entire dependency tree
      let(:resolution_specifications) do
        [
          { name: 'foo',   origin: :forge, version: '1.0.0' },
          { name: 'bar',   origin: :forge, version: '1.0.0' },
          { name: 'baz',   origin: :forge, version: '1.0.0' },
          { name: 'qux',   origin: :forge, version: '1.0.0' },
          { name: 'waldo', origin: :forge, version: '1.0.0' },
        ]
      end
      let(:resolution_dependencies) do
        [
          { origin: 'foo',   destination: 'bar',  version_requirement: '>= 0' },
          { origin: 'bar',   destination: 'baz',  version_requirement: '>= 0' },
          { origin: 'baz',   destination: 'qux',  version_requirement: '>= 0' },
          { origin: 'waldo',  destination: 'baz', version_requirement: '>= 0' },
        ]
      end

      it 'should return transient DocumentMissingModuleError' do
        errors = subject.resolution_validation_errors(resolution_result)
        expect(errors.count).to eq(3)

        error = errors[0]
        expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentMissingDependenciesError)
        expect(error).to have_attributes(
          message:                /foo/,
          module_specification:   @module_specifications['foo'],
          puppet_module:          @document_modules[0],
          missing_specifications: [@module_specifications['bar'], @module_specifications['qux']]
        )

        error = errors[1]
        expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentMissingDependenciesError)
        expect(error).to have_attributes(
          message:                /baz/,
          module_specification:   @module_specifications['baz'],
          puppet_module:          @document_modules[1],
          missing_specifications: [@module_specifications['qux']]
        )

        error = errors[2]
        expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentMissingDependenciesError)
        expect(error).to have_attributes(
          message:                /waldo/,
          module_specification:   @module_specifications['waldo'],
          puppet_module:          @document_modules[2],
          missing_specifications: [@module_specifications['qux']]
        )
      end
    end
  end
end

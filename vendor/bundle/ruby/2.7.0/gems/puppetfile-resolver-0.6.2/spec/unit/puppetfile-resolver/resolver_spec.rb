require 'spec_helper'

require 'puppetfile-resolver/resolver'
require 'puppetfile-resolver/puppetfile'

describe PuppetfileResolver::Resolver do
  let(:puppet_version) { nil }
  let(:subject) { PuppetfileResolver::Resolver.new(puppetfile_document, puppet_version) }
  let(:cache) { MockLocalModuleCache.new }
  let(:default_resolve_options) { { cache: cache } }
  let(:resolve_options) { default_resolve_options }

  RSpec.shared_examples 'a resolver flag' do |flag|
    context "Given a document without the flag" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }

      it 'should resolve with error' do
        expect{ subject.resolve(resolve_options) }.to raise_error do |error|
          expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
          expect(error.puppetfile_modules).to eq([puppetfile_module])
        end
      end
    end

    context "Given a document with the flag" do
      let(:puppetfile_module) do
        PuppetfileResolver::Puppetfile::LocalModule.new('module1').tap { |obj| obj.resolver_flags << flag }
      end

      it 'should resolve without error' do
        result = subject.resolve(resolve_options)

        expect(result.specifications).to include('module1')
      end
    end
  end

  # Helper to create an empty, but valid puppetfile document
  def valid_document(content)
    PuppetfileResolver::Puppetfile::Document.new(content).tap { |d| d.forge_uri = 'https://foo.local' }
  end

  before(:each) do
    # Disable all but the local spec searcher
    allow(PuppetfileResolver::SpecSearchers::Forge).to receive(:find_all).and_return([])
    allow(PuppetfileResolver::SpecSearchers::Git).to receive(:find_all).and_return([])
    allow(PuppetfileResolver::SpecSearchers::Forge).to receive(:module_metadata).and_return({})
  end

  describe '.resolve' do
    context 'Given an invalid document' do
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(PuppetfileResolver::Puppetfile::InvalidModule.new('invalid_module'))
        doc
      end

      it 'should resolve with error' do
        expect{ subject.resolve(resolve_options) }.to raise_error(RuntimeError, /is not valid/)
      end
    end

    context "Given a document with no modules" do
      let(:puppetfile_document) { valid_document('foo') }

      it 'should resolve without error' do
        expect{ subject.resolve(resolve_options) }.to_not raise_error
      end

      it 'should resolve no modules' do
        result = subject.resolve(resolve_options)

        modules = result.specifications.select { |_, spec| spec.is_a?(PuppetfileResolver::Models::ModuleSpecification) }
        expect(modules).to be_empty
      end
    end

    context "Given a document with missing modules" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('missing_module') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      context "and Allow Missing Modules option is true" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: true) }

        it 'should resolve without error' do
          expect{ subject.resolve(resolve_options) }.to_not raise_error
        end

        it 'should resolve with a missing module specification' do
          result = subject.resolve(resolve_options)

          modules = result.specifications.select { |_, spec| spec.is_a?(PuppetfileResolver::Models::MissingModuleSpecification) }
          expect(modules['missing_module']).to_not be_nil
        end
      end

      context "and Allow Missing Modules option is false" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: false) }

        it 'should resolve with error' do
          expect{ subject.resolve(resolve_options) }.to raise_error do |error|
            expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
            expect(error.puppetfile_modules).to eq([puppetfile_module])
          end
        end
      end
    end

    context "Given a document with missing dependant modules" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        cache.add_local_module_spec(
          'module1',
          [{ name: 'missing_module', version_requirement: '>= 0' }]
        )
      end

      context "and Allow Missing Modules option is true" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: true) }

        it 'should resolve without error' do
          expect{ subject.resolve(resolve_options) }.to_not raise_error
        end

        it 'should resolve with a missing module specification' do
          result = subject.resolve(resolve_options)
          modules = result.specifications.select { |_, spec| spec.is_a?(PuppetfileResolver::Models::MissingModuleSpecification) }
          expect(modules['missing_module']).to_not be_nil
        end

        it 'should resolve with a found module specification' do
          result = subject.resolve(resolve_options)

          modules = result.specifications.select { |_, spec| spec.is_a?(PuppetfileResolver::Models::ModuleSpecification) }
          expect(modules['module1']).to_not be_nil
        end
      end

      context "and Allow Missing Modules option is false" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: false) }

        it 'should resolve with error' do
          expect{ subject.resolve(resolve_options) }.to raise_error do |error|
            expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
            expect(error.puppetfile_modules).to eq([puppetfile_module])
          end
        end
      end
    end

    context "Given a document with unresolvable dependencies" do
      let(:puppetfile_module1) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_module2) { PuppetfileResolver::Puppetfile::LocalModule.new('module2') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module1)
        doc.add_module(puppetfile_module2)
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2, but the version specification makes this not possible
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2', version_requirement: '>= 2.0.0' }]
        )
        cache.add_local_module_spec('module2', [], nil, '1.0.0')
      end

      context "and Allow Missing Modules option is true" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: true) }

        it 'should resolve without error' do
          expect{ subject.resolve(resolve_options) }.to_not raise_error
        end

        it 'should resolve ignoring the unresolvable module' do
          result = subject.resolve(resolve_options)

          expect(result.specifications).to_not include('module2')
        end

        it 'should resolve with a found module specification' do
          result = subject.resolve(resolve_options)

          modules = result.specifications.select { |_, spec| spec.is_a?(PuppetfileResolver::Models::ModuleSpecification) }
          expect(modules['module1']).to_not be_nil
        end
      end

      context "and Allow Missing Modules option is false" do
        let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: false) }

        it 'should resolve with error' do
          expect{ subject.resolve(resolve_options) }.to raise_error do |error|
            expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
            expect(error.puppetfile_modules).to eq([puppetfile_module1, puppetfile_module2])
          end
        end
      end
    end

    context "Given a document with resolvable dependencies" do
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(PuppetfileResolver::Puppetfile::LocalModule.new('module1'))
        doc.add_module(PuppetfileResolver::Puppetfile::LocalModule.new('module2'))
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2, and the version specification is possible
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2', version_requirement: '>= 2.0.0' }]
        )
        cache.add_local_module_spec('module2', [], nil, '2.0.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve without error' do
            expect{ subject.resolve(resolve_options) }.to_not raise_error
          end

          it 'should resolve with found module specifications' do
            result = subject.resolve(resolve_options)

            expect(result.specifications).to include('module1')
            expect(result.specifications).to include('module2')
          end
        end
      end
    end

    context "Given a document with resolvable version range dependencies" do
      [
        { range: '> 1.0.0 < 3.0.0', expected_version: '2.0.0' },
        { range: '< 2.5.0',         expected_version: '2.0.0' },
        { range: '<= 2.0.0',        expected_version: '2.0.0' },
        { range: '>= 2.0.0',        expected_version: '3.0.0' },
        { range: '= 1.0.0',         expected_version: '1.0.0' },
        { range: :latest,           expected_version: '3.0.0' },
        { range: nil,               expected_version: '3.0.0' }
      ].each do |range_testcase|
        describe "With a range of '#{range_testcase[:range]}'" do
          let(:puppetfile_document) do
            doc = valid_document('foo')
            doc.add_module(PuppetfileResolver::Puppetfile::LocalModule.new('module1').tap { |o| o.version = range_testcase[:range] })
            doc
          end

          before(:each) do
            cache.add_local_module_spec('module1', [], nil, '1.0.0')
            cache.add_local_module_spec('module1', [], nil, '2.0.0')
            cache.add_local_module_spec('module1', [], nil, '3.0.0')
          end

          [true, false].each do |testcase|
            context "and Allow Missing Modules option is #{testcase}" do
              let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

              it 'should resolve without error' do
                expect{ subject.resolve(resolve_options) }.to_not raise_error
              end

              it 'should resolve with found module specifications' do
                result = subject.resolve(resolve_options)

                expect(result.specifications).to include('module1')
                expect(result.specifications['module1'].version.to_s).to eq(range_testcase[:expected_version])
              end
            end
          end
        end
      end
    end

    context "Given a document with a resolvable Puppet requirement" do
      let(:puppet_version) { '3.0.0' }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(PuppetfileResolver::Puppetfile::LocalModule.new('module1'))
        doc
      end

      before(:each) do
        # Version 1.0 of Module 1 depends Puppet < 2.x
        cache.add_local_module_spec('module1', [], '< 2.0.0',          '1.0.0')
        # Version 2.0 of Module 1 depends Puppet 3.x
        cache.add_local_module_spec('module1', [], '>= 3.0.0 < 4.0.0', '2.0.0')
        # Version 2.1 of Module 1 also depends Puppet 3.x
        cache.add_local_module_spec('module1', [], '>= 3.0.0 < 4.0.0', '2.1.0')
        # Version 3.0 of Module 1 depends Puppet 4.x
        cache.add_local_module_spec('module1', [], '>= 4.0.0 < 5.0.0', '3.0.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve without error' do
            expect{ subject.resolve(resolve_options) }.to_not raise_error
          end

          it 'should resolve with the most appropriate specification' do
            result = subject.resolve(resolve_options)

            expect(result.specifications).to include('module1')
            expect(result.specifications['module1'].version.to_s).to eq('2.1.0')
          end
        end
      end
    end

    context "Given a document with resolvable but legacy module definition" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2', version_range: '> 1.0.0 < 2.0.0' }]
        )
        cache.add_local_module_spec('module2', [], nil, '2.0.0')
        cache.add_local_module_spec('module2', [], nil, '1.5.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve with the most appropriate specification' do
            result = subject.resolve(resolve_options)

            expect(result.specifications).to include('module2')
            expect(result.specifications['module2'].version.to_s).to eq('1.5.0')
          end
        end
      end
    end

    context "Given a document with resolvable but partial module definition" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2' }]
        )
        cache.add_local_module_spec('module2', [], nil, '2.0.0')
        cache.add_local_module_spec('module2', [], nil, '1.5.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve with the most appropriate specification' do
            result = subject.resolve(resolve_options)

            expect(result.specifications).to include('module2')
            expect(result.specifications['module2'].version.to_s).to eq('2.0.0')
          end
        end
      end
    end

    context "Given a document with a unresolvable Puppet requirement" do
      let(:puppet_version) { '99.99.99' }
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Version 1.0 of Module 1 depends module2
        cache.add_local_module_spec('module1', [{ name: 'module2', version_requirement: '>= 0' }])
        cache.add_local_module_spec('module2', [], '< 2.0.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve with error' do
            expect{ subject.resolve(resolve_options) }.to raise_error do |error|
              expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
              expect(error.puppetfile_modules).to eq([puppetfile_module])
            end
          end
        end
      end
    end

    context 'Using the resolver flag DISABLE_PUPPET_DEPENDENCY_FLAG' do
      let(:puppet_version) { '99.99.99' }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Version 1.0 of Module 1 depends Puppet < 2.x
        cache.add_local_module_spec('module1', [], '< 2.0.0',          '1.0.0')
        # Version 2.0 of Module 1 depends Puppet 3.x
        cache.add_local_module_spec('module1', [], '>= 3.0.0 < 4.0.0', '2.0.0')
      end

      it_behaves_like 'a resolver flag', PuppetfileResolver::Puppetfile::DISABLE_PUPPET_DEPENDENCY_FLAG
    end

    context 'Using the resolver flag DISABLE_ALL_DEPENDENCIES_FLAG' do
      # Need to set allow_missing_modules to false so it raises errors
      let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: false) }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2, but the version specification makes this not possible
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2', version_requirement: '>= 2.0.0' }]
        )
        cache.add_local_module_spec('module2', [], nil, '1.0.0')
      end

      it_behaves_like 'a resolver flag', PuppetfileResolver::Puppetfile::DISABLE_ALL_DEPENDENCIES_FLAG
    end

    context "Given a document with an explicit module version that does not exist" do
      let(:puppet_version) { '3.0.0' }
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1').tap { |m| m.version = '2.0.0' } }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Only version 1.0 of Module 1
        cache.add_local_module_spec('module1', [], nil, '1.0.0')
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve with error' do
            expect{ subject.resolve(resolve_options) }.to raise_error do |error|
              expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentVersionConflictError)
              expect(error.puppetfile_modules).to eq([puppetfile_module])
            end
          end
        end
      end
    end

    context "Given a document with circular dependencies" do
      let(:puppetfile_module) { PuppetfileResolver::Puppetfile::LocalModule.new('module1') }
      let(:puppetfile_document) do
        doc = valid_document('foo')
        doc.add_module(puppetfile_module)
        doc
      end

      before(:each) do
        # Module 1 depends on Module 2
        cache.add_local_module_spec(
          'module1',
          [{ name: 'module2', version_requirement: '>= 1.0.0' }]
        )
        # Module 2 depends on Module 3
        cache.add_local_module_spec(
          'module2',
          [{ name: 'module3', version_requirement: '>= 1.0.0' }]
        )
        # Module 3 depends on Module 1  <--- This causes a circular dependency
        cache.add_local_module_spec(
          'module3',
          [{ name: 'module1', version_requirement: '>= 1.0.0' }]
        )
      end

      [true, false].each do |testcase|
        context "and Allow Missing Modules option is #{testcase}" do
          let(:resolve_options) { default_resolve_options.merge(allow_missing_modules: testcase) }

          it 'should resolve with error' do
            expect{ subject.resolve(resolve_options) }.to raise_error do |error|
              expect(error).to be_a(PuppetfileResolver::Puppetfile::DocumentCircularDependencyError)
              expect(error.puppetfile_modules).to eq([puppetfile_module])
            end
          end
        end
      end
    end
  end
end

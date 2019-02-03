require 'spec_helper'

describe 'PuppetLanguageServer::PuppetHelper' do

  shared_examples_for 'a base Puppet object' do
    [:key, :calling_source, :source, :line, :char, :length, :origin, :from_sidecar!].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end
  end

  describe 'PuppetClass' do
    let(:subject) { PuppetLanguageServer::PuppetHelper::PuppetClass.new }

    let(:puppet_classname) { :rspec_class }
    let(:sidecar_puppet_class) { random_sidecar_puppet_class }

    it_should_behave_like 'a base Puppet object'

    # No additional methods to test
    # [:doc].each do |testcase|
    #   it "instance should respond to #{testcase}" do
    #     expect(subject).to respond_to(testcase)
    #   end
    # end

    describe '#from_sidecar!' do
      it 'should populate from a sidecar function object' do
        subject.from_sidecar!(sidecar_puppet_class)

        expect(subject.key).to eq(sidecar_puppet_class.key)
        expect(subject.calling_source).to eq(sidecar_puppet_class.calling_source)
        expect(subject.source).to eq(sidecar_puppet_class.source)
        expect(subject.line).to eq(sidecar_puppet_class.line)
        expect(subject.char).to eq(sidecar_puppet_class.char)
        expect(subject.length).to eq(sidecar_puppet_class.length)
      end
    end
  end

  describe 'PuppetFunction' do
    let(:subject) { PuppetLanguageServer::PuppetHelper::PuppetFunction.new }

    let(:sidecar_puppet_func) { random_sidecar_puppet_function }

    it_should_behave_like 'a base Puppet object'

    [:doc, :type, :version, :signatures].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_sidecar!' do
      it 'should populate from a sidecar function object' do
        subject.from_sidecar!(sidecar_puppet_func)

        expect(subject.key).to eq(sidecar_puppet_func.key)
        expect(subject.calling_source).to eq(sidecar_puppet_func.calling_source)
        expect(subject.source).to eq(sidecar_puppet_func.source)
        expect(subject.line).to eq(sidecar_puppet_func.line)
        expect(subject.char).to eq(sidecar_puppet_func.char)
        expect(subject.length).to eq(sidecar_puppet_func.length)
        expect(subject.doc).to eq(sidecar_puppet_func.doc)
        expect(subject.type).to eq(sidecar_puppet_func.type)
        expect(subject.version).to eq(sidecar_puppet_func.version)
        expect(subject.signatures).to eq(sidecar_puppet_func.signatures)
      end
    end
  end

  describe 'PuppetType' do
    let(:subject) { PuppetLanguageServer::PuppetHelper::PuppetType.new }

    let(:sidecar_puppet_type) { random_sidecar_puppet_type }

    it_should_behave_like 'a base Puppet object'

    [:doc, :attributes, :allattrs, :parameters, :properties, :meta_parameters].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_sidecar!' do
      it 'should populate from a sidecar type object' do
        subject.from_sidecar!(sidecar_puppet_type)

        expect(subject.key).to eq(sidecar_puppet_type.key)
        expect(subject.calling_source).to eq(sidecar_puppet_type.calling_source)
        expect(subject.source).to eq(sidecar_puppet_type.source)
        expect(subject.line).to eq(sidecar_puppet_type.line)
        expect(subject.char).to eq(sidecar_puppet_type.char)
        expect(subject.length).to eq(sidecar_puppet_type.length)
        expect(subject.doc).to eq(sidecar_puppet_type.doc)
        expect(subject.attributes).to eq(sidecar_puppet_type.attributes)
      end
    end
  end
end

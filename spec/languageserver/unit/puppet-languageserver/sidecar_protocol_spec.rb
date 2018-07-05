require 'spec_helper'

describe 'PuppetLanguageServer::Sidecar::Protocol' do

  shared_examples_for 'a base Sidecar Protocol object' do
    [:to_json, :from_json!].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end

      it 'should serialize to a string' do
        serial = subject.to_json

        expect(serial).to be_a(String)
      end
    end
  end

  shared_examples_for 'a base Sidecar Protocol Puppet object' do
    [:key, :calling_source, :source, :line, :char, :length, :to_h, :from_h!].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end
  end

  shared_examples_for 'a base Sidecar Protocol Puppet object list' do
    [:to_json, :from_json!, :child_type].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end
  end

  shared_examples_for 'a round trip capable object list' do
    [:to_json, :from_json!, :child_type].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end
  end

  shared_examples_for 'a serializable object list' do
    it "should deserialize a serialized list" do
      serial = subject.to_json
      deserial = subject_klass.new.from_json!(serial)

      expect(deserial.length).to eq(subject.length)
      subject.each_with_index do |_item, index|
        expect(deserial[index].to_h).to eq(subject[index].to_h)
      end
    end
  end

  basepuppetobject_properties = [:key, :calling_source, :source, :line, :char, :length]
  puppetclass_properties = []
  puppetfunction_properties = [:doc, :arity, :type]
  puppettype_properties = [:doc, :attributes]

  describe 'BasePuppetObject' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::BasePuppetObject }
    let(:subject) {
      value = subject_klass.new
      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    basepuppetobject_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      basepuppetobject_properties.each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetClass' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetClass }
    let(:subject) {
      value = subject_klass.new
      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    puppetclass_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (basepuppetobject_properties + puppetclass_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetClassList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetClassList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_class
      value << random_sidecar_puppet_class
      value << random_sidecar_puppet_class
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetClass" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetClass)
    end
  end

  describe 'PuppetFunction' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunction }
    let(:subject) {
      value = subject_klass.new
      value.doc = 'doc'
      value.arity = 'arity'
      value.type = :type
      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    puppetfunction_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (basepuppetobject_properties + puppetfunction_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetFunctionList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_function
      value << random_sidecar_puppet_function
      value << random_sidecar_puppet_function
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetClass" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetFunction)
    end
  end

  describe 'PuppetType' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetType }
    let(:subject) {
      value = subject_klass.new
      value.doc = 'doc'
      value.attributes = {
        :attr_name1 => { :type => :attr_type, :doc => 'attr_doc1', :required? => false },
        :attr_name2 => { :type => :attr_type, :doc => 'attr_doc2', :required? => false }
      }
      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    puppettype_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (basepuppetobject_properties + puppettype_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetTypeList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_type
      value << random_sidecar_puppet_type
      value << random_sidecar_puppet_type
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetClass" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetType)
    end
  end
end

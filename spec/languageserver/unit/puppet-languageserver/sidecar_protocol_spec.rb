require 'spec_helper'

describe 'PuppetLanguageServer::Sidecar::Protocol' do

  shared_examples_for 'a base Sidecar Protocol object' do
    [:to_json, :from_json!].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    it 'should serialize to a string' do
      serial = subject.to_json

      expect(serial).to be_a(String)
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
  nodegraph_properties = [:dot_content, :error_content]
  puppetclass_properties = [:doc, :parameters]
  puppetfunction_properties = [:doc, :function_version, :signatures]
  puppetfunctionsignature_properties = [:key, :doc, :return_types, :parameters]
  puppetfunctionsignatureparameter_properties = [:name, :types, :doc, :signature_key_offset, :signature_key_length ]
  puppettype_properties = [:doc, :attributes]
  resource_properties = [:manifest]

  describe 'ActionParams' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::ActionParams }
    let(:subject) {
      value = subject_klass.new
      value['val1_' + rand(1000).to_s] = rand(1000).to_s
      value['val2_' + rand(1000).to_s] = rand(1000).to_s
      value['val3_' + rand(1000).to_s] = rand(1000).to_s
      value
    }

    it_should_behave_like 'a base Sidecar Protocol object'

    describe '#from_json!' do
      it "should deserialize a serialized value" do
        serial = subject.to_json
        deserial = subject_klass.new.from_json!(serial)

        subject.keys.each do |key|
          expect(deserial[key]).to eq(deserial[key])
        end
      end
    end
  end

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

  describe 'NodeGraph' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::NodeGraph }
    let(:subject) {
      value = subject_klass.new
      value.dot_content = 'dot_content_' + rand(1000).to_s
      value.error_content = 'error_content_' + rand(1000).to_s
      value
    }

    it_should_behave_like 'a base Sidecar Protocol object'

    describe '#from_json!' do
      nodegraph_properties.each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          #require 'pry'; binding.pry
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
      value.doc = 'doc'
      value.parameters = {
        "attr_name1" => { :type => "Optional[String]", :doc => 'attr_doc1' },
        "attr_name2" => { :type => "String", :doc => 'attr_doc2' }
      }
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
      value.function_version = 4
      value.signatures = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureList.new
      value.signatures << random_sidecar_puppet_function_signature
      value.signatures << random_sidecar_puppet_function_signature
      value.signatures << random_sidecar_puppet_function_signature
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

    it "instance should have a childtype of PuppetFunction" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetFunction)
    end
  end

  describe 'PuppetFunctionSignature' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignature }
    let(:subject) {
      value = subject_klass.new
      value.key = 'something(Any a, String[1,1] b'
      value.doc = 'doc'
      value.return_types = ['Any', 'Undef']
      value.parameters << random_sidecar_puppet_function_signature_parameter
      value.parameters << random_sidecar_puppet_function_signature_parameter
      value
    }

    puppetfunctionsignature_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (puppetfunctionsignature_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetFunctionSignatureList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_function_signature
      value << random_sidecar_puppet_function_signature
      value << random_sidecar_puppet_function_signature
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetFunctionSignature" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignature)
    end
  end

  describe 'PuppetFunctionSignatureParameter' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureParameter }
    let(:subject) {
      value = subject_klass.new
      value.name = 'param1'
      value.types = ['Undef']
      value.doc = 'doc'
      value.signature_key_offset = nil
      value.signature_key_length = 5
      value
    }

    puppetfunctionsignatureparameter_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (puppetfunctionsignatureparameter_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetFunctionSignatureParameterList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureParameterList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_function_signature_parameter
      value << random_sidecar_puppet_function_signature_parameter
      value << random_sidecar_puppet_function_signature_parameter
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetFunctionSignatureParameter" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureParameter)
    end
  end

  describe 'PuppetType' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetType }
    let(:subject) {
      value = subject_klass.new
      value.doc = 'doc'
      value.attributes = {
        :attr_name1 => { :type => :attr_type, :doc => 'attr_doc1', :required? => false, :isnamevar? => false },
        :attr_name2 => { :type => :attr_type, :doc => 'attr_doc2', :required? => false, :isnamevar? => true }
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

    it "instance should have a childtype of PuppetType" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetType)
    end
  end

  describe 'Resource' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::Resource }
    let(:subject) { random_sidecar_resource }

    it_should_behave_like 'a base Sidecar Protocol object'

    resource_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      resource_properties.each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'ResourceList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::ResourceList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_resource
      value << random_sidecar_resource
      value << random_sidecar_resource
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of Resource" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::Resource)
    end
  end
end

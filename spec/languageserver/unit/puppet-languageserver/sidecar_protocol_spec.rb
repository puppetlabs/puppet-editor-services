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

    it 'should roundtrip to_json to from_json!' do
      subject_as_json = subject.to_json
      copy = subject_klass.new.from_json!(subject_as_json)
      expect(copy.to_json).to eq(subject_as_json)
      expect(copy.hash).to eq(subject.hash)
    end
  end

  shared_examples_for 'a base Sidecar Protocol Puppet object' do
    [:key, :calling_source, :source, :line, :char, :length, :to_h, :from_h!].each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    it_should_behave_like 'a round trip capable hash'
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

  shared_examples_for 'a round trip capable hash' do
    it 'should roundtrip to_h to from_h!' do
      subject_as_hash = subject.to_h
      copy = subject_klass.new.from_h!(subject_as_hash)
      expect(subject_as_hash).to eq(copy.to_h)
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
  fact_properties = [:value]
  nodegraph_properties = [:json_content, :error_content]
  puppetclass_properties = [:doc, :parameters]
  puppetdatatype_properties = [:doc, :alias_of, :attributes, :is_type_alias]
  puppetdatatypeattribute_properties = [:key, :doc, :default_value, :types]
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
          expect(deserial[key]).to eq(subject[key])
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

  describe 'Fact' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::Fact }
    let(:subject) {
      value = subject_klass.new
      value.value = 'value'
      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    fact_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (basepuppetobject_properties + fact_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'FactList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::FactList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_fact
      value << random_sidecar_fact
      value << random_sidecar_fact
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of Fact" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::Fact)
    end
  end

  describe 'NodeGraph' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::NodeGraph }
    let(:subject) {
      value = subject_klass.new
      value.json_content = 'json_content_' + rand(1000).to_s
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

  describe 'PuppetDataType' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetDataType }
    let(:subject) {
      value = subject_klass.new
      value.doc = 'doc'
      value.alias_of = 'alias_of'
      value.is_type_alias = true
      value.attributes << random_sidecar_puppet_datatype_attribute
      value.attributes << random_sidecar_puppet_datatype_attribute

      add_default_basepuppetobject_values!(value)
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object'

    puppetdatatype_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      (basepuppetobject_properties + puppetdatatype_properties).each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetDataTypeList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_datatype
      value << random_sidecar_puppet_datatype
      value << random_sidecar_puppet_datatype
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetDataType" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetDataType)
    end
  end

  describe 'PuppetDataTypeAttribute' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeAttribute }
    let(:subject) {
      value = subject_klass.new
      value.key = 'attr1'
      value.doc = 'doc'
      value.default_value = 'default+value'
      value.types = 'String'
      value
    }

    it_should_behave_like 'a base Sidecar Protocol object'
    it_should_behave_like 'a round trip capable hash'

    puppetdatatypeattribute_properties.each do |testcase|
      it "instance should respond to #{testcase}" do
        expect(subject).to respond_to(testcase)
      end
    end

    describe '#from_json!' do
      puppetdatatypeattribute_properties.each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject.to_json
          deserial = subject_klass.new.from_json!(serial)

          expect(deserial.send(testcase)).to eq(subject.send(testcase))
        end
      end
    end
  end

  describe 'PuppetDataTypeAttributeList' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeAttributeList }
    let(:subject) {
      value = subject_klass.new
      value << random_sidecar_puppet_datatype_attribute
      value << random_sidecar_puppet_datatype_attribute
      value << random_sidecar_puppet_datatype_attribute
      value
    }

    it_should_behave_like 'a base Sidecar Protocol Puppet object list'

    it_should_behave_like 'a serializable object list'

    it "instance should have a childtype of PuppetDataTypeAttribute" do
      expect(subject.child_type).to eq(PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeAttribute)
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

  describe 'AggregateMetadata' do
    let(:subject_klass) { PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata }
    let(:subject) {
      value = subject_klass.new
      (1..3).each do |_|
        value.append!(random_sidecar_puppet_class)
        value.append!(random_sidecar_puppet_datatype)
        value.append!(random_sidecar_puppet_function)
        value.append!(random_sidecar_puppet_type)
      end
      value
    }

    it_should_behave_like 'a base Sidecar Protocol object'
  end
end

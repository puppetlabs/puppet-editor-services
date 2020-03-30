require 'spec_helper'

describe 'PuppetLanguageServerSidecar::Protocol' do

  shared_examples_for 'a base Sidecar Protocol extended object' do
    [:from_puppet].each do |testcase|
      it "instance should respond to class extension #{testcase}" do
        expect(subject.class).to respond_to(testcase)
      end
    end
  end

  describe 'NodeGraph' do
    let(:subject_klass) { PuppetLanguageServerSidecar::Protocol::PuppetNodeGraph }
    let(:subject) { subject_klass.new }

    it "instance should respond to set_error" do
      expect(subject).to respond_to(:set_error)
      result = subject.set_error('test_error')
      expect(result.vertices).to eq(nil)
      expect(result.edges).to eq(nil)
      expect(result.error_content).to eq('test_error')
    end
  end

  describe 'PuppetClass' do
    let(:subject_klass) { PuppetLanguageServerSidecar::Protocol::PuppetClass }
    let(:subject) { subject_klass.new }

    let(:puppet_classname) { :rspec_class }
    let(:puppet_class) {
      {
        'name'       => 'class_name',
        'type'       => :class,
        'doc'        => 'doc',
        'parameters' => { }, # TODO: Need to test this for reals
        'source'     => 'source',
        'line'       => 1,
        'char'       => 1,
      }
    }

    it_should_behave_like 'a base Sidecar Protocol extended object'

    describe '.from_puppet' do
      it 'should populate from a constructed hash' do
        result = subject_klass.from_puppet(puppet_classname, puppet_class, nil)

        expect(result.doc).to eq(puppet_class['doc'])
        expect(result.parameters.count).to eq(puppet_class['parameters'].count)
      end
    end

    describe '#from_json' do
      [:doc, :parameters].each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject_klass.from_puppet(puppet_classname, puppet_class, nil)
          deserial = subject_klass.new.from_json!(serial.to_json)

          expect(deserial.send(testcase)).to eq(serial.send(testcase))
        end
      end
    end
  end

  describe 'PuppetFunction' do
    let(:subject_klass) { PuppetLanguageServerSidecar::Protocol::PuppetFunction }
    let(:subject) { subject_klass.new }

    let(:puppet_funcname) { :rspec_function }
    let(:puppet_func) {
      {
        :doc             => 'function documentation',
        :arity           => 0,
        :type            => :statement,
        :source_location => {
          :source => 'source',
          :line   => 1,
        }
      }
    }

    it_should_behave_like 'a base Sidecar Protocol extended object'

    describe '.from_puppet' do
      it 'should populate from a Puppet function object' do
        result = subject_klass.from_puppet(puppet_funcname, puppet_func)
        # This method is only called for V3 API functions.
        # Therefore we need to assert the V3 function into V4 metadata

        expect(result.doc).to match(puppet_func[:doc])
        expect(result.function_version).to eq(3)
        expect(result.signatures.count).to eq(1)
        expect(result.signatures[0].doc).to match(puppet_func[:doc])
        expect(result.signatures[0].key).to eq("#{puppet_funcname}()")
      end
    end

    describe '#from_json' do
      [:doc, :function_version, :signatures].each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject_klass.from_puppet(puppet_funcname, puppet_func)
          deserial = subject_klass.new.from_json!(serial.to_json)

          expect(deserial.send(testcase)).to eq(serial.send(testcase))
        end
      end
    end
  end

  describe 'PuppetType' do
    let(:subject_klass) { PuppetLanguageServerSidecar::Protocol::PuppetType }
    let(:subject) { subject_klass.new }

    let(:puppet_typename) { :rspec_class }
    let(:puppet_type) {
      # Get a real puppet type
      Puppet::Type.type(:user)
    }

    it_should_behave_like 'a base Sidecar Protocol extended object'

    describe '.from_puppet' do
      it 'should populate from a Puppet function object' do
        result = subject_klass.from_puppet(puppet_typename, puppet_type)

        expect(result.doc).to eq(puppet_type.doc)
        expect(result.attributes.count).to eq(puppet_type.allattrs.count)
      end
    end

    describe '#from_json' do
      [:doc, :attributes].each do |testcase|
        it "should deserialize a serialized #{testcase} value" do
          serial = subject_klass.from_puppet(puppet_typename, puppet_type)
          deserial = subject_klass.new.from_json!(serial.to_json)

          expect(deserial.send(testcase)).to eq(serial.send(testcase))
        end
      end
    end
  end
end

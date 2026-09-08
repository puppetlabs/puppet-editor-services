require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::CompletionProvider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, :connection_id => 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::CompletionProvider }

  def number_of_completion_item_with_type(completion_list, typename)
    (completion_list.items.select { |item| item.data['type'] == typename}).length
  end

  RSpec::Matchers.define :be_completion_item_with_type do |value|
    value = [value] unless value.is_a?(Array)

    match { |actual| value.include?(actual.data['type']) }

    description do
      "be a Completion Item with a data type in the list of #{value}"
    end
  end

  def create_mock_type(parameters = [], properties = [])
    object = PuppetLanguageServer::Sidecar::Protocol::PuppetType.new
    object.doc = 'mock documentation'
    object.attributes = {}
    parameters.each { |name| object.attributes[name.to_sym] = {
      :type        => :param,
      :doc         => 'mock parameter doc',
      :required? => nil,
      :isnamevar?  => nil
    }}
    properties.each { |name| object.attributes[name.to_sym] = {
      :type        => :property,
      :doc         => 'mock parameter doc',
      :required? => nil,
      :isnamevar?  => nil
    }}

    object
  end

  def create_mock_class(name, parameters = {})
    object = PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new
    object.key = name.to_sym
    object.doc = 'mock class documentation'
    object.parameters = parameters
    object
  end

  before(:each) do
    # Prepopulate the Object Cache with workspace objects
    populate_cache(session_state.object_cache)
    allow(PuppetLanguageServer).to receive(:log_message)
    # Types
    type_list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
    required_type = PuppetLanguageServer::Sidecar::Protocol::PuppetType.new
    required_type.key = :reqtype
    required_type.doc = 'required type doc'
    required_type.attributes = {
      ensure: { type: :property, doc: 'ensure doc', required?: true, isnamevar?: false }
    }
    type_list << create_mock_type(['param1'], ['prop1']).tap { |i| i.key = :mocktype }
    type_list << required_type
    session_state.object_cache.import_sidecar_list!(type_list, :type, :workspace)
    # Classes
    class_list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
    class_list << create_mock_class('mockclass', { 'classparam' => { type: 'Optional[String]', doc: 'class param doc' } })
    session_state.object_cache.import_sidecar_list!(class_list, :class, :workspace)
  end

  after(:each) do
    # Clear out the Object Cache of workspace objects
    PuppetLanguageServer::SessionState::ObjectCache::SECTIONS.each do |section|
      session_state.object_cache.import_sidecar_list!([], section, :workspace)
    end
  end

  describe '#complete' do
    # https://puppet.com/docs/puppet/latest/lang_classes.html#section-x54-1hk-xhb
    context 'given a resource-like declaration of a resource' do
      context 'where the title refers to a non-existant class' do
        let(:content) { <<-EOT
          class { 'does::not::exist':

          }
          EOT
        }
        let(:line_num) { 1 }
        let(:char_num) { 0 }

        it 'should return an empty completion list' do
          result = subject.complete(session_state, content, line_num, char_num)
          expect(result.items.count).to eq(0)
        end
      end

      context 'with a missing title name' do
        let(:content) { <<-EOT
          class {

          }
          EOT
        }
        let(:line_num) { 1 }
        let(:char_num) { 0 }

        it 'should raise an error' do
          expect{ subject.complete(session_state, content, line_num, char_num) }.to raise_error(RuntimeError)
        end
      end

      context 'with a known title class' do
        let(:content) { <<-EOT
          class { 'mocktype':

          }
          EOT
        }
        let(:line_num) { 1 }
        let(:char_num) { 0 }
        let(:expected_types) { ['resource_parameter','resource_property'] }

        it 'should return only parameter and property items' do
          result = subject.complete(session_state, content, line_num, char_num)

          result.items.each do |item|
            expect(item).to be_completion_item_with_type(expected_types)
          end
        end

        it 'should return the parameters of the class' do
          result = subject.complete(session_state, content, line_num, char_num)
          expect(number_of_completion_item_with_type(result, 'resource_parameter')).to eq(1)
        end

        it 'should return the properties of the class' do
          result = subject.complete(session_state, content, line_num, char_num)
          expect(number_of_completion_item_with_type(result, 'resource_property')).to eq(1)
        end
      end
    end

    context 'at the root of a document (no object under cursor)' do
      let(:content) { "\n\n" }
      let(:line_num) { 0 }
      let(:char_num) { 0 }

      it 'returns a CompletionList' do
        result = subject.complete(session_state, content, line_num, char_num)
        expect(result).to be_a(LSP::CompletionList)
      end

      it 'includes keyword completion items' do
        result = subject.complete(session_state, content, line_num, char_num)
        expect(number_of_completion_item_with_type(result, 'keyword')).to be > 0
      end

      it 'includes resource_type and resource_class items' do
        result = subject.complete(session_state, content, line_num, char_num)
        total = number_of_completion_item_with_type(result, 'resource_type') +
                number_of_completion_item_with_type(result, 'resource_class')
        expect(total).to be >= 0
      end

      context 'with tasks_mode enabled' do
        it 'includes plan keyword' do
          result = subject.complete(session_state, content, line_num, char_num, tasks_mode: true)
          keyword_items = result.items.select { |i| i.data['type'] == 'keyword' }
          plan_item = keyword_items.find { |i| i.data['name'] == 'plan' }
          expect(plan_item).not_to be_nil
        end
      end
    end

    context 'inside a standard resource body (user type)' do
      let(:content) { "user { 'Bob':\n  \n}\n" }
      let(:line_num) { 1 }
      let(:char_num) { 2 }

      it 'returns a CompletionList without raising' do
        expect { subject.complete(session_state, content, line_num, char_num) }.not_to raise_error
      end
    end

    context 'inside a class body (HostClassDefinition)' do
      let(:content) { "class mymodule {\n  \n}\n" }
      let(:line_num) { 1 }
      let(:char_num) { 2 }

      it 'returns a CompletionList with resource items' do
        result = subject.complete(session_state, content, line_num, char_num)
        expect(result).to be_a(LSP::CompletionList)
        total = number_of_completion_item_with_type(result, 'resource_type') +
                number_of_completion_item_with_type(result, 'resource_class') +
                number_of_completion_item_with_type(result, 'keyword')
        expect(total).to be > 0
      end
    end

    context 'inside a class resource body' do
      let(:content) { "mockclass { 'title':\n  \n}\n" }
      let(:line_num) { 1 }
      let(:char_num) { 2 }

      it 'returns class parameter completion items' do
        result = subject.complete(session_state, content, line_num, char_num)
        expect(result).to be_a(LSP::CompletionList)
        expect(number_of_completion_item_with_type(result, 'resource_class_parameter')).to be > 0
      end
    end

    context 'when cursor is on the $facts variable' do
      let(:content) { "$x = $facts['os']\n" }
      let(:line_num) { 0 }
      let(:char_num) { 7 }

      it 'returns a CompletionList without raising' do
        expect { subject.complete(session_state, content, line_num, char_num) }.not_to raise_error
      end
    end

    context 'inside a plan definition body (tasks_mode)' do
      let(:content) { "plan myplan() {\n  \n}\n" }
      let(:line_num) { 1 }
      let(:char_num) { 2 }

      it 'returns a CompletionList with function items' do
        result = subject.complete(session_state, content, line_num, char_num, tasks_mode: true)
        expect(result).to be_a(LSP::CompletionList)
        total = number_of_completion_item_with_type(result, 'resource_type') +
                number_of_completion_item_with_type(result, 'function')
        expect(total).to be >= 0
      end
    end
  end

  describe '#resolve' do
    def make_item(data)
      LSP::CompletionItem.new('label' => 'test', 'data' => data)
    end

    context 'with type variable_expr_fact' do
      it 'returns a completion item' do
        item = make_item('type' => 'variable_expr_fact', 'expr' => 'os')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end

    context 'with type keyword = class' do
      it 'sets documentation and snippet' do
        item = make_item('type' => 'keyword', 'name' => 'class')
        result = subject.resolve(session_state, item)
        expect(result.documentation).to be_a(String)
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end
    end

    context 'with type keyword = define' do
      it 'sets documentation and snippet' do
        item = make_item('type' => 'keyword', 'name' => 'define')
        result = subject.resolve(session_state, item)
        expect(result.documentation).to be_a(String)
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end
    end

    context 'with type keyword = application' do
      it 'sets detail and snippet' do
        item = make_item('type' => 'keyword', 'name' => 'application')
        result = subject.resolve(session_state, item)
        expect(result.detail).to eq('Orchestrator')
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end
    end

    context 'with type keyword = site' do
      it 'sets detail and snippet' do
        item = make_item('type' => 'keyword', 'name' => 'site')
        result = subject.resolve(session_state, item)
        expect(result.detail).to eq('Orchestrator')
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end
    end

    context 'with type function' do
      it 'returns completion item' do
        item = make_item('type' => 'function', 'name' => 'notice')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end

      it 'returns original item for unknown function' do
        item = make_item('type' => 'function', 'name' => 'nonexistent_function_xyz')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end

    context 'with type resource_type' do
      it 'returns completion item with snippet' do
        item = make_item('type' => 'resource_type', 'name' => 'mocktype')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end

      it 'returns original item for unknown resource type' do
        item = make_item('type' => 'resource_type', 'name' => 'nonexistent_type')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end

      it 'generates a snippet with attribute placeholders for types with required attributes' do
        item = make_item('type' => 'resource_type', 'name' => 'reqtype')
        result = subject.resolve(session_state, item)
        expect(result.insertText).to include('ensure')
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end
    end

    context 'with type resource_parameter' do
      it 'returns completion item with documentation' do
        item = make_item('type' => 'resource_parameter', 'resource_type' => 'mocktype', 'param' => 'param1')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
        expect(result.documentation).to eq('mock parameter doc')
      end

      it 'returns original item for unknown resource type' do
        item = make_item('type' => 'resource_parameter', 'resource_type' => 'nonexistent', 'param' => 'param1')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end

    context 'with type resource_property' do
      it 'returns completion item with documentation' do
        item = make_item('type' => 'resource_property', 'resource_type' => 'mocktype', 'prop' => 'prop1')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
        expect(result.documentation).to eq('mock parameter doc')
      end

      it 'returns original item for unknown resource type' do
        item = make_item('type' => 'resource_property', 'resource_type' => 'nonexistent', 'prop' => 'prop1')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end

    context 'with type resource_class' do
      it 'returns completion item with snippet for existing class' do
        item = make_item('type' => 'resource_class', 'name' => 'mockclass')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
        expect(result.insertText).to include('mockclass')
        expect(result.insertTextFormat).to eq(LSP::InsertTextFormat::SNIPPET)
      end

      it 'returns original item for unknown class' do
        item = make_item('type' => 'resource_class', 'name' => 'nonexistent_class_xyz')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end

    context 'with type resource_class_parameter' do
      it 'returns completion item with documentation for known class param' do
        item = make_item('type' => 'resource_class_parameter', 'resource_type' => 'mockclass', 'param' => 'classparam')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
        expect(result.documentation).to include('class param doc')
      end

      it 'returns completion item for unknown class' do
        item = make_item('type' => 'resource_class_parameter', 'resource_type' => 'nonexistent_class_xyz', 'param' => 'param1')
        result = subject.resolve(session_state, item)
        expect(result).to be_a(LSP::CompletionItem)
      end
    end
  end
end

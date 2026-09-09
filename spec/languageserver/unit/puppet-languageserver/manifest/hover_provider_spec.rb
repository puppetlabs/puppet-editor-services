require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::HoverProvider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, connection_id: 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::HoverProvider }

  before(:each) do
    populate_cache(session_state.object_cache)
    allow(PuppetLanguageServer).to receive(:log_message)

    # Add a mock class with parameters for class attribute hover tests
    class_list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
    mock_class = PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new
    mock_class.key = :hovermockclass
    mock_class.doc = nil
    mock_class.parameters = { 'classparam' => { type: 'Optional[String]', doc: 'param doc' } }
    class_list << mock_class
    session_state.object_cache.import_sidecar_list!(class_list, :class, :workspace)

    # Add a mock type with a param attribute for param hover tests
    type_list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
    mock_type = PuppetLanguageServer::Sidecar::Protocol::PuppetType.new
    mock_type.key = :hovermocktype
    mock_type.doc = nil
    mock_type.attributes = {
      mockparam: { type: :param, doc: 'param attr doc', required?: false, isnamevar?: false },
      mockprop:  { type: :property, doc: 'prop attr doc', required?: false, isnamevar?: false }
    }
    type_list << mock_type
    session_state.object_cache.import_sidecar_list!(type_list, :type, :workspace)
  end

  describe '#resolve' do
    context 'with a resource expression' do
      let(:content) { "user { 'Bob':\n  ensure => 'present',\n}\n" }

      it 'returns nil or a hover result without raising' do
        # Cursor on 'user' keyword
        expect { subject.resolve(session_state, content, 0, 2) }.not_to raise_error
      end
    end

    context 'when cursor is on blank space (no meaningful token)' do
      let(:content) { "# just a comment\nclass foo { }\n" }

      it 'returns nil' do
        result = subject.resolve(session_state, content, 0, 0)
        expect(result).to be_nil
      end
    end

    context 'with a function call' do
      let(:content) { "notice('hello')\n" }

      it 'returns nil or a hover result without raising' do
        result = subject.resolve(session_state, content, 0, 2)
        expect { result }.not_to raise_error
      end
    end

    context 'with a variable expression' do
      let(:content) { "$myvar = 'hello'\nnotice($myvar)\n" }

      it 'returns without raising' do
        result = subject.resolve(session_state, content, 1, 8)
        expect { result }.not_to raise_error
      end
    end

    context 'with malformed puppet content' do
      let(:content) { "user { 'Bob'" }

      it 'raises an error' do
        expect { subject.resolve(session_state, content, 0, 1) }.to raise_error(RuntimeError)
      end
    end

    context 'with cursor on a resource attribute (AttributeOperation)' do
      # cursor on "ensure" at line 1, char 4
      let(:content) { "user { 'Bob':\n  ensure => 'present',\n}\n" }

      it 'returns without raising' do
        expect { subject.resolve(session_state, content, 1, 4) }.not_to raise_error
      end
    end

    context 'with tasks_mode enabled' do
      let(:content) { "notice('hello')\n" }

      it 'returns without raising' do
        expect { subject.resolve(session_state, content, 0, 2, tasks_mode: true) }.not_to raise_error
      end
    end

    context 'with cursor on a param attribute of a puppet type' do
      let(:content) { "hovermocktype { 'test':\n  mockparam => 'value',\n}\n" }

      it 'returns without raising' do
        expect { subject.resolve(session_state, content, 1, 4) }.not_to raise_error
      end
    end

    context 'with cursor on an attribute of a class resource' do
      let(:content) { "hovermockclass { 'test':\n  classparam => 'value',\n}\n" }

      it 'returns without raising' do
        expect { subject.resolve(session_state, content, 1, 4) }.not_to raise_error
      end
    end
  end

  describe '#get_attribute_type_parameter_content' do
    it 'returns a string with the parameter name' do
      mock_type = double('puppet_type')
      allow(mock_type).to receive(:attributes).and_return({ ensure: { type: :param, doc: 'doc for ensure', required?: false } })
      result = subject.get_attribute_type_parameter_content(mock_type, :ensure)
      expect(result).to be_a(String)
      expect(result).to include('ensure')
    end

    it 'includes doc when present' do
      mock_type = double('puppet_type')
      allow(mock_type).to receive(:attributes).and_return({ ensure: { type: :param, doc: 'some doc', required?: false } })
      result = subject.get_attribute_type_parameter_content(mock_type, :ensure)
      expect(result).to include('some doc')
    end
  end

  describe '#get_attribute_type_property_content' do
    it 'returns a string with the property name' do
      mock_type = double('puppet_type')
      allow(mock_type).to receive(:attributes).and_return({ ensure: { type: :property, doc: 'doc for ensure', required?: false } })
      result = subject.get_attribute_type_property_content(mock_type, :ensure)
      expect(result).to be_a(String)
      expect(result).to include('ensure')
    end

    it 'includes _required_ marker for required properties' do
      mock_type = double('puppet_type')
      allow(mock_type).to receive(:attributes).and_return({ ensure: { type: :property, doc: 'doc', required?: true } })
      result = subject.get_attribute_type_property_content(mock_type, :ensure)
      expect(result).to include('required')
    end
  end

  describe '#get_attribute_class_parameter_content' do
    let(:mock_class) { double('puppet_class') }

    it 'returns nil when param is not found' do
      allow(mock_class).to receive(:parameters).and_return({})
      result = subject.get_attribute_class_parameter_content(mock_class, 'nonexistent')
      expect(result).to be_nil
    end

    it 'returns a string with the parameter name' do
      allow(mock_class).to receive(:parameters).and_return({ 'myparam' => { doc: nil } })
      result = subject.get_attribute_class_parameter_content(mock_class, 'myparam')
      expect(result).to be_a(String)
      expect(result).to include('myparam')
    end

    it 'includes doc when present' do
      allow(mock_class).to receive(:parameters).and_return({ 'myparam' => { doc: 'class param doc' } })
      result = subject.get_attribute_class_parameter_content(mock_class, 'myparam')
      expect(result).to include('class param doc')
    end

    it 'returns content without doc when doc is nil' do
      allow(mock_class).to receive(:parameters).and_return({ 'myparam' => { doc: nil } })
      result = subject.get_attribute_class_parameter_content(mock_class, 'myparam')
      expect(result).to eq('**myparam** Parameter')
    end
  end

  describe '#get_fact_content' do
    it 'returns nil when fact does not exist' do
      allow(PuppetLanguageServer::FacterHelper).to receive(:fact).and_return(nil)
      result = subject.get_fact_content(session_state, 'nonexistent_fact')
      expect(result).to be_nil
    end

    it 'returns string content for a string fact value' do
      mock_fact = double('fact', value: 'Linux')
      allow(PuppetLanguageServer::FacterHelper).to receive(:fact).and_return(mock_fact)
      result = subject.get_fact_content(session_state, 'kernel')
      expect(result).to be_a(String)
      expect(result).to include('kernel')
      expect(result).to include('Linux')
    end

    it 'returns JSON-formatted content for a Hash fact value' do
      mock_fact = double('fact', value: { 'family' => 'RedHat' })
      allow(PuppetLanguageServer::FacterHelper).to receive(:fact).and_return(mock_fact)
      result = subject.get_fact_content(session_state, 'os')
      expect(result).to include('os')
      expect(result).to include('```')
      expect(result).to include('RedHat')
    end
  end

  describe '#get_hover_content_for_access_expression' do
    context 'with expr == "facts" and eContents available' do
      it 'returns fact content when fact array has more than one element' do
        fact_elem = double('fact_elem', value: 'kernel')
        fact_array = double('fact_array')
        allow(fact_array).to receive(:respond_to?).with(:eContents).and_return(true)
        allow(fact_array).to receive(:eContents).and_return([double('first'), fact_elem])
        mock_fact = double('fact', value: 'Linux')
        allow(PuppetLanguageServer::FacterHelper).to receive(:fact).and_return(mock_fact)
        result = subject.get_hover_content_for_access_expression(session_state, [fact_array], 'facts')
        expect(result).to include('kernel')
      end

      it 'returns nil when fact array has only one element' do
        fact_array = double('fact_array')
        allow(fact_array).to receive(:respond_to?).with(:eContents).and_return(true)
        allow(fact_array).to receive(:eContents).and_return([double('only_element')])
        result = subject.get_hover_content_for_access_expression(session_state, [fact_array], 'facts')
        expect(result).to be_nil
      end
    end

    context 'with expr == "facts" using _pcore_contents' do
      it 'returns nil when pcore_contents yields no elements' do
        fact_array = double('fact_array')
        allow(fact_array).to receive(:respond_to?).with(:eContents).and_return(false)
        allow(fact_array).to receive(:_pcore_contents)
        result = subject.get_hover_content_for_access_expression(session_state, [fact_array], 'facts')
        expect(result).to be_nil
      end
    end

    context 'with a ::variable_name (top-scope variable)' do
      it 'calls get_fact_content with the variable name (without ::)' do
        mock_fact = double('fact', value: 'Linux')
        allow(PuppetLanguageServer::FacterHelper).to receive(:fact).with(session_state, 'kernel').and_return(mock_fact)
        result = subject.get_hover_content_for_access_expression(session_state, [], '::kernel')
        expect(result).to include('kernel')
      end

      it 'returns nil when fact not found for :: variable' do
        allow(PuppetLanguageServer::FacterHelper).to receive(:fact).and_return(nil)
        result = subject.get_hover_content_for_access_expression(session_state, [], '::nonexistent_xyz')
        expect(result).to be_nil
      end
    end
  end

  describe '#get_resource_expression_content' do
    let(:mock_item) { double('resource_item') }

    before do
      name_double = double('name', value: 'myclass')
      allow(mock_item).to receive(:type_name).and_return(name_double)
    end

    context 'when resource is a puppet class' do
      let(:mock_class) do
        double('puppet_class',
               key: 'myclass',
               doc: 'class doc',
               parameters: { 'param1' => { doc: 'p1 doc' } })
      end

      before do
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_type).and_return(nil)
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_class).and_return(mock_class)
      end

      it 'returns class content string' do
        result = subject.get_resource_expression_content(session_state, mock_item)
        expect(result).to be_a(String)
        expect(result).to include('myclass')
      end
    end

    context 'when resource is a puppet class with no doc and no parameters' do
      let(:mock_class) do
        double('puppet_class', key: 'myclass', doc: nil, parameters: {})
      end

      before do
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_type).and_return(nil)
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_class).and_return(mock_class)
      end

      it 'returns class content without extra sections' do
        result = subject.get_resource_expression_content(session_state, mock_item)
        expect(result).to include('myclass')
      end
    end

    context 'when resource is neither a type nor a class' do
      before do
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_type).and_return(nil)
        allow(PuppetLanguageServer::PuppetHelper).to receive(:get_class).and_return(nil)
      end

      it 'raises a RuntimeError' do
        expect { subject.get_resource_expression_content(session_state, mock_item) }.to raise_error(RuntimeError, /not a valid puppet type/)
      end
    end
  end

  describe '#resolve with QualifiedReference (datatype)' do
    let(:content) { "$x = Integer\n" }

    context 'when datatype exists' do
      let(:mock_dt) { double('dt_info', is_type_alias: false, doc: nil) }

      before do
        allow(PuppetLanguageServer::PuppetHelper).to receive(:datatype).and_return(mock_dt)
      end

      it 'returns LSP::Hover with Data Type content' do
        result = subject.resolve(session_state, content, 0, 7)
        expect(result).to be_a(LSP::Hover)
        expect(result.contents).to include('Data Type')
      end
    end

    context 'when datatype is a type alias with doc' do
      let(:mock_dt) { double('dt_info', is_type_alias: true, doc: 'alias doc', alias_of: 'String') }

      before do
        allow(PuppetLanguageServer::PuppetHelper).to receive(:datatype).and_return(mock_dt)
      end

      it 'includes Alias marker and alias_of in content' do
        result = subject.resolve(session_state, content, 0, 7)
        expect(result.contents).to include('Alias')
        expect(result.contents).to include('alias doc')
      end
    end
  end
end

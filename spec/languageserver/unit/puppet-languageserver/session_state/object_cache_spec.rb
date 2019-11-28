require 'spec_helper'

describe 'PuppetLanguageServer::SessionState::ObjectCache' do
  let(:section_function) { :function }
  let(:origin_default) { :default }
  let(:origin_workspace) { :workspace }

  let(:subject) { PuppetLanguageServer::SessionState::ObjectCache.new() }

  describe "#import_sidecar_list!" do
    # Note that this method is used a lot in the test fixtures below so it
    # doesn't require an exhaustive test suite
    it 'should import an array of sidecar objects' do
      obj1 = random_sidecar_puppet_function
      obj1.key = :func1
      obj2 = random_sidecar_puppet_function
      obj2.key = :func2
      subject.import_sidecar_list!([obj1, obj2], section_function, origin_default)

      expect(subject.object_names_by_section(section_function)).to eq([:func1, :func2])
    end
  end

  describe "#remove_section!" do
    let(:origin_foo) { :foo }
    let(:origin_bar) { :bar }

    before(:each) do
      obj1 = random_sidecar_puppet_function
      obj1.key = :func1
      obj2 = random_sidecar_puppet_function
      obj2.key = :func2
      obj3 = random_sidecar_puppet_class
      obj3.key = :class3
      obj4 = random_sidecar_puppet_class
      obj4.key = :class4
      obj5 = random_sidecar_puppet_class
      obj5.key = :class5

      list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      list << obj1
      list << obj2
      subject.import_sidecar_list!(list, :function, origin_default)
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      list << obj3
      subject.import_sidecar_list!(list, :class, origin_default)
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      list << obj4
      subject.import_sidecar_list!(list, :class, origin_foo)
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      list << obj5
      subject.import_sidecar_list!(list, :class, origin_bar)
    end

    it 'should not remove non-matching section' do
      subject.remove_section!(:type)

      expect(subject.object_names_by_section(:function)).to eq([:func1, :func2])
      expect(subject.object_names_by_section(:class)).to eq([:class3, :class4, :class5])
    end

    it 'should not remove non-matching section and origin' do
      subject.remove_section!(:class, :does_not_match)

      expect(subject.object_names_by_section(:function)).to eq([:func1, :func2])
      expect(subject.object_names_by_section(:class)).to eq([:class3, :class4, :class5])
    end

    it 'should only remove matching section and origin' do
      subject.remove_section!(:class, origin_foo)

      expect(subject.object_names_by_section(:function)).to eq([:func1, :func2])
      expect(subject.object_names_by_section(:class)).to eq([:class3, :class5])
    end

    it 'should only remove matching section' do
      subject.remove_section!(:class)

      expect(subject.object_names_by_section(:function)).to eq([:func1, :func2])
      expect(subject.object_names_by_section(:class)).to eq([])
    end
  end

  context "given a populated cache" do
    before(:each) do
      func1 = random_sidecar_puppet_function
      func1.key = :func1
      func2 = random_sidecar_puppet_function
      func2.key = :func2
      func3 = random_sidecar_puppet_function
      func3.key = :func3
      func4 = random_sidecar_puppet_function
      func4.key = :func4

      class1 = random_sidecar_puppet_class
      class1.key = :class1
      class2 = random_sidecar_puppet_class
      class2.key = :class2

      list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      list << func1
      list << func2
      subject.import_sidecar_list!(list, section_function, origin_default)
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      list << func3
      list << func4
      subject.import_sidecar_list!(list, section_function, origin_workspace)
      list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      list << class1
      list << class2
      subject.import_sidecar_list!(list, :class, origin_workspace)
    end

    describe '#object_by_name' do
      it 'should get existing items from the cache' do
        expect(subject.object_by_name(section_function, :func1).key).to eq(:func1)
      end

      it 'should return nil for objects that do not exist' do
        expect(subject.object_by_name(:doesnotexist, :func1)).to be_nil
        expect(subject.object_by_name(section_function, :doesnotexist)).to be_nil
      end
    end

    describe '#object_names_by_section' do
      it 'should get existing items from the cache' do
        expect(subject.object_names_by_section(section_function)).to eq([:func1, :func2, :func3, :func4])
      end

      it 'should return empty array for objects that do not exist' do
        expect(subject.object_names_by_section(:doesnotexist)).to eq([])
      end
    end

    describe '#objects_by_section' do
      it 'should get existing items from the cache' do
        result = []
        subject.objects_by_section(section_function) { |_name, obj| result << obj.key.to_s }
        expect(result).to eq(['func1', 'func2', 'func3', 'func4'])
      end

      it 'should not yield for sections that do not exist' do
        result = []
        subject.objects_by_section(:doesnotexist) { |_name, obj| result << obj }
        expect(result).to eq([])
      end
    end

    describe '#all_objects' do
      it 'should yield all objects in the cache' do
        result = []
        subject.all_objects { |_name, obj| result << obj.key.to_s }
        expect(result).to eq(['func1', 'func2', 'func3', 'func4', 'class1', 'class2'])
      end
    end
  end
end

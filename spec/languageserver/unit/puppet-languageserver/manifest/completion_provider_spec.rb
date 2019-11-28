require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::CompletionProvider' do
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
    parameters.each { |name| object.attributes[name] = {
      :type        => :param,
      :doc         => 'mock parameter doc',
      :required? => nil,
      :isnamevar?  => nil
    }}
    properties.each { |name| object.attributes[name] = {
      :type        => :property,
      :doc         => 'mock parameter doc',
      :required? => nil,
      :isnamevar?  => nil
    }}

    object
  end

  before(:all) do
    # TODO: This shouldn't really be required, but the PuppetHelper seems to require the default types to be loaded
    # in order to query the cache.  This is wrong.
    wait_for_puppet_loading
  end

  before(:each) do
    # Prepopulate the Object Cache with workspace objects
    # Types
    list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
    list << create_mock_type(['param1'], ['prop1']).tap { |i| i.key = :mocktype }
    PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!(list, :type, :workspace)
  end

  after(:each) do
    # Clear out the Object Cache of workspace objects
    PuppetLanguageServer::SessionState::ObjectCache::SECTIONS.each do |section|
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], section, :workspace)
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
          result = subject.complete(content, line_num, char_num)
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
          expect{ subject.complete(content, line_num, char_num) }.to raise_error(RuntimeError)
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
          result = subject.complete(content, line_num, char_num)

          result.items.each do |item|
            expect(item).to be_completion_item_with_type(expected_types)
          end
        end

        it 'should return the parameters of the class' do
          result = subject.complete(content, line_num, char_num)
          expect(number_of_completion_item_with_type(result, 'resource_parameter')).to eq(1)
        end

        it 'should return the properties of the class' do
          result = subject.complete(content, line_num, char_num)
          expect(number_of_completion_item_with_type(result, 'resource_property')).to eq(1)
        end
      end
    end
  end
end

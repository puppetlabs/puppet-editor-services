require 'spec_helper'

describe 'PuppetLanguageServer::PuppetHelper' do
  describe '#load_static_data' do
    def contains_bolt_objects?(cache)
      !cache.object_by_name(:datatype, 'Boltlib::PlanResult').nil? &&
      !cache.object_by_name(:datatype, 'Boltlib::TargetSpec').nil?
    end

    before(:each) do
      # Purge the static data
      PuppetLanguageServer::PuppetHelper::Cache::SECTIONS.each do |section|
        PuppetLanguageServer::PuppetHelper.cache.remove_section!(section, :bolt)
      end
     expect(contains_bolt_objects?(PuppetLanguageServer::PuppetHelper.cache)).to be(false)
    end

    it 'loads without error' do
      PuppetLanguageServer::PuppetHelper.load_static_data

      expect(contains_bolt_objects?(PuppetLanguageServer::PuppetHelper.cache)).to be(true)
    end
  end

  describe '#static_data_loaded?' do
    before(:each) do
      PuppetLanguageServer::PuppetHelper.instance_variable_set(:@static_data_loaded, nil)
    end

    it 'sets static_data_loaded? to true after loading' do
      expect(PuppetLanguageServer::PuppetHelper.static_data_loaded?).to be(false)
      PuppetLanguageServer::PuppetHelper.load_static_data
      expect(PuppetLanguageServer::PuppetHelper.static_data_loaded?).to be(true)
    end
  end
end

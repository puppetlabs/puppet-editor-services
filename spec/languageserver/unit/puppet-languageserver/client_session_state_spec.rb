require 'spec_helper'

describe 'PuppetLanguageServer::ClientSessionState' do
  let(:server) do
    MockServer.new({}, {}, {}, { :class => PuppetLanguageServer::MessageHandler })
  end
  let(:async) { false } # Always load synchoronously for rspec testing
  let(:subject) { PuppetLanguageServer::ClientSessionState.new(server.handler_object) }

  describe '#load_static_data!' do
    def contains_bolt_objects?(cache)
      !cache.object_by_name(:datatype, 'Boltlib::PlanResult').nil? &&
      !cache.object_by_name(:datatype, 'Boltlib::TargetSpec').nil?
    end

    it 'loads without error' do
      subject.load_static_data!(async)

      expect(contains_bolt_objects?(subject.object_cache)).to be(true)
    end
  end

  describe '#static_data_loaded?' do
    it 'sets static_data_loaded? to true after loading' do
      expect(subject.static_data_loaded?).to be(false)
      subject.load_static_data!(async)
      expect(subject.static_data_loaded?).to be(true)
    end
  end
end

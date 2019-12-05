require 'spec_helper'
require 'puppet-languageserver/session_state/document_store'

describe 'validation_queue' do
  VALIDATE_MANIFEST_FILENAME = 'file:///something.pp'
  VALIDATE_PUPPETFILE_FILENAME = 'file:///Puppetfile'
  VALIDATE_EPP_FILENAME = 'file:///something.epp'
  VALIDATE_UNKNOWN_FILENAME = 'file:///I_do_not_work.exe'
  VALIDATE_MISSING_FILENAME = 'file:///I_do_not_exist.jpg'
  VALIDATE_FILE_CONTENT = "file_content which causes errros\n <%- Wee!\n class 'foo' {'"

  let(:subject) { PuppetLanguageServer::GlobalQueues::ValidationQueue.new }
  let(:connection_id) { 'abc123' }
  let(:document_version) { 10 }
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, :connection_id => 'mock') }
  let(:document_store) { session_state.documents }

  before(:each) do
    document_store.clear
    allow(subject).to receive(:session_state_from_connection_id).with(connection_id).and_return(session_state)
  end

  def job(file_uri, document_version, connection_id, job_options = {})
    PuppetLanguageServer::GlobalQueues::ValidationQueueJob.new(file_uri, document_version, connection_id, job_options)
  end

  describe '#enqueue' do
    shared_examples_for "single document which sends validation results" do |file_uri, file_content, validation_result|
      it 'should send validation results' do
        document_store.set_document(file_uri, file_content, document_version)
        expect(subject).to receive(:send_diagnostics).with(connection_id, file_uri, validation_result)

        subject.enqueue(file_uri, document_version, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    before(:each) do
      allow(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Manifest::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Epp::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Puppetfile::ValidationProvider.validate mock should not be called")
    end

    context 'for an invalid or missing documents' do
      it 'should not return validation results' do
        document_store.set_document(VALIDATE_MANIFEST_FILENAME, VALIDATE_FILE_CONTENT, document_version)

        expect(subject).to_not receive(:send_diagnostics)

        subject.enqueue(VALIDATE_MANIFEST_FILENAME, document_version + 1, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    context 'for a multiple items in the queue' do
      let(:file_content0) { VALIDATE_FILE_CONTENT + "_0" }
      let(:file_content1) { VALIDATE_FILE_CONTENT + "_1" }
      let(:file_content2) { VALIDATE_FILE_CONTENT + "_2" }
      let(:file_content3) { VALIDATE_FILE_CONTENT + "_3" }
      let(:validation_result) { [{ 'result' => 'MockResult' }] }
      let(:validation_options) { { :resolve_puppetfile => false } }

      it 'should only return the most recent validation results' do
        # Configure the document store
        document_store.set_document(VALIDATE_MANIFEST_FILENAME,   file_content0, document_version + 0)
        document_store.set_document(VALIDATE_MANIFEST_FILENAME,   file_content1, document_version + 1)
        document_store.set_document(VALIDATE_MANIFEST_FILENAME,   file_content3, document_version + 3)
        document_store.set_document(VALIDATE_EPP_FILENAME,        file_content1, document_version + 1)
        document_store.set_document(VALIDATE_PUPPETFILE_FILENAME, file_content1, document_version + 1)

        # Preconfigure the validation queue
        subject.reset_queue([
          job(VALIDATE_MANIFEST_FILENAME,   document_version + 0, connection_id),
          job(VALIDATE_MANIFEST_FILENAME,   document_version + 1, connection_id),
          job(VALIDATE_MANIFEST_FILENAME,   document_version + 3, connection_id),
          job(VALIDATE_EPP_FILENAME,        document_version + 1, connection_id),
          job(VALIDATE_PUPPETFILE_FILENAME, document_version + 1, connection_id),
        ])

        # We only expect the following results to be returned
        expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(session_state, file_content2, Hash).and_return(validation_result)
        expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(file_content1).and_return(validation_result)
        expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(file_content1, Hash).and_return(validation_result)
        expect(subject).to receive(:send_diagnostics).with(connection_id, VALIDATE_MANIFEST_FILENAME, validation_result)
        expect(subject).to receive(:send_diagnostics).with(connection_id, VALIDATE_EPP_FILENAME, validation_result)
        expect(subject).to receive(:send_diagnostics).with(connection_id, VALIDATE_PUPPETFILE_FILENAME, validation_result)

        # Simulate a new document being added, by adding it to the document store and
        # enqueue validation for a version that it's in the middle of the versions in the queue
        document_store.set_document(VALIDATE_MANIFEST_FILENAME, file_content2, document_version + 2)
        subject.enqueue(VALIDATE_MANIFEST_FILENAME, document_version + 2, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    context 'for a single item in the queue' do
      context 'of a puppet manifest file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(session_state, VALIDATE_FILE_CONTENT, Hash).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", VALIDATE_MANIFEST_FILENAME, VALIDATE_FILE_CONTENT, validation_result
      end

      context 'of a Puppetfile file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(VALIDATE_FILE_CONTENT, Hash).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", VALIDATE_PUPPETFILE_FILENAME, VALIDATE_FILE_CONTENT, validation_result
      end

      context 'of a EPP template file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(VALIDATE_FILE_CONTENT).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", VALIDATE_EPP_FILENAME, VALIDATE_FILE_CONTENT, validation_result
      end

      context 'of a unknown file' do
        validation_result = []

        it_should_behave_like "single document which sends validation results", VALIDATE_UNKNOWN_FILENAME, VALIDATE_FILE_CONTENT, validation_result
      end
    end
  end

  describe '#execute' do
    shared_examples_for "document which sends validation results" do |file_uri, file_content, validation_result|
      it 'should send validation results' do
        document_store.set_document(file_uri, file_content, document_version)
        expect(subject).to receive(:send_diagnostics).with(connection_id, file_uri, validation_result)

        subject.execute(file_uri, document_version, connection_id)
      end
    end

    before(:each) do
      allow(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Manifest::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Epp::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Puppetfile::ValidationProvider.validate mock should not be called")
    end

    it 'should not send validation results for documents that do not exist' do
      expect(subject).to_not receive(:send_diagnostics)

      subject.execute(VALIDATE_MISSING_FILENAME, 1, connection_id)
    end

    context 'for a puppet manifest file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(session_state, VALIDATE_FILE_CONTENT, Hash).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", VALIDATE_MANIFEST_FILENAME, VALIDATE_FILE_CONTENT, validation_result
    end

    context 'for a Puppetfile file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(VALIDATE_FILE_CONTENT, Hash).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", VALIDATE_PUPPETFILE_FILENAME, VALIDATE_FILE_CONTENT, validation_result
    end

    context 'for an EPP template file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(VALIDATE_FILE_CONTENT).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", VALIDATE_EPP_FILENAME, VALIDATE_FILE_CONTENT, validation_result
    end

    context 'for an unknown file' do
      validation_result = []

      it_should_behave_like "document which sends validation results", VALIDATE_UNKNOWN_FILENAME, VALIDATE_FILE_CONTENT, validation_result
    end
  end
end

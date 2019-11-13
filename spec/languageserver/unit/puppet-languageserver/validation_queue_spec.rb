require 'spec_helper'

describe 'validation_queue' do
  MANIFEST_FILENAME = 'file:///something.pp'
  PUPPETFILE_FILENAME = 'file:///Puppetfile'
  EPP_FILENAME = 'file:///something.epp'
  UNKNOWN_FILENAME = 'file:///I_do_not_work.exe'
  MISSING_FILENAME = 'file:///I_do_not_exist.jpg'
  FILE_CONTENT = "file_content which causes errros\n <%- Wee!\n class 'foo' {'"

  let(:subject) { PuppetLanguageServer::ValidationQueue }
  let(:connection_id) { 'abc123' }
  let(:document_version) { 10 }

  describe '#enqueue' do
    shared_examples_for "single document which sends validation results" do |file_uri, file_content, validation_result|
      it 'should send validation results' do
        subject.documents.set_document(file_uri, file_content, document_version)
        expect(PuppetLanguageServer::ValidationQueue).to receive(:send_diagnostics).with(connection_id, file_uri, validation_result)

        subject.enqueue(file_uri, document_version, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    before(:each) do
      subject.documents.clear

      allow(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Manifest::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Epp::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Puppetfile::ValidationProvider.validate mock should not be called")
    end

    context 'for an invalid or missing documents' do
      it 'should not return validation results' do
        subject.documents.set_document(MANIFEST_FILENAME, FILE_CONTENT, document_version)

        expect(PuppetLanguageServer::ValidationQueue).to_not receive(:send_diagnostics)

        subject.enqueue(MANIFEST_FILENAME, document_version + 1, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    context 'for a multiple items in the queue' do
      let(:file_content0) { FILE_CONTENT + "_0" }
      let(:file_content1) { FILE_CONTENT + "_1" }
      let(:file_content2) { FILE_CONTENT + "_2" }
      let(:file_content3) { FILE_CONTENT + "_3" }
      let(:validation_result) { [{ 'result' => 'MockResult' }] }

      before(:each) do
      end

      it 'should only return the most recent validation results' do
        # Configure the document store
        subject.documents.set_document(MANIFEST_FILENAME,   file_content0, document_version + 0)
        subject.documents.set_document(MANIFEST_FILENAME,   file_content1, document_version + 1)
        subject.documents.set_document(MANIFEST_FILENAME,   file_content3, document_version + 3)
        subject.documents.set_document(EPP_FILENAME,        file_content1, document_version + 1)
        subject.documents.set_document(PUPPETFILE_FILENAME, file_content1, document_version + 1)

        # Preconfigure the validation queue
        subject.reset_queue([
          { 'file_uri' => MANIFEST_FILENAME,   'doc_version' => document_version + 0, 'document_type' => :manifest,   'connection_id' => connection_id },
          { 'file_uri' => MANIFEST_FILENAME,   'doc_version' => document_version + 1, 'document_type' => :manifest,   'connection_id' => connection_id },
          { 'file_uri' => MANIFEST_FILENAME,   'doc_version' => document_version + 3, 'document_type' => :manifest,   'connection_id' => connection_id },
          { 'file_uri' => EPP_FILENAME,        'doc_version' => document_version + 1, 'document_type' => :epp,        'connection_id' => connection_id },
          { 'file_uri' => PUPPETFILE_FILENAME, 'doc_version' => document_version + 1, 'document_type' => :puppetfile, 'connection_id' => connection_id },
        ])

        # We only expect the following results to be returned
        expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(file_content2, Hash).and_return(validation_result)
        expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(file_content1).and_return(validation_result)
        expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(file_content1).and_return(validation_result)
        expect(PuppetLanguageServer::ValidationQueue).to receive(:send_diagnostics).with(connection_id, MANIFEST_FILENAME, validation_result)
        expect(PuppetLanguageServer::ValidationQueue).to receive(:send_diagnostics).with(connection_id, EPP_FILENAME, validation_result)
        expect(PuppetLanguageServer::ValidationQueue).to receive(:send_diagnostics).with(connection_id, PUPPETFILE_FILENAME, validation_result)

        # Simulate a new document begin added by adding it to the document store and
        # enqueue validation for a version that it's in the middle of the versions in the queue
        subject.documents.set_document(MANIFEST_FILENAME, file_content2, document_version + 2)
        subject.enqueue(MANIFEST_FILENAME, document_version + 2, connection_id)
        # Wait for the thread to complete
        subject.drain_queue
      end
    end

    context 'for a single item in the queue' do
      context 'of a puppet manifest file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(FILE_CONTENT, Hash).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", MANIFEST_FILENAME, FILE_CONTENT, validation_result
      end

      context 'of a Puppetfile file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(FILE_CONTENT).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", PUPPETFILE_FILENAME, FILE_CONTENT, validation_result
      end

      context 'of a EPP template file' do
        validation_result = [{ 'result' => 'MockResult' }]

        before(:each) do
          expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(FILE_CONTENT).and_return(validation_result)
        end

        it_should_behave_like "single document which sends validation results", EPP_FILENAME, FILE_CONTENT, validation_result
      end

      context 'of a unknown file' do
        validation_result = []

        it_should_behave_like "single document which sends validation results", UNKNOWN_FILENAME, FILE_CONTENT, validation_result
      end
    end
  end

  describe '#validate_sync' do
    shared_examples_for "document which sends validation results" do |file_uri, file_content, validation_result|
      it 'should send validation results' do
        subject.documents.set_document(file_uri, file_content, document_version)
        expect(PuppetLanguageServer::ValidationQueue).to receive(:send_diagnostics).with(connection_id, file_uri, validation_result)

        subject.validate_sync(file_uri, document_version, connection_id, )
      end
    end

    before(:each) do
      subject.documents.clear

      allow(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Manifest::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Epp::ValidationProvider.validate mock should not be called")
      allow(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).and_raise("PuppetLanguageServer::Puppetfile::ValidationProvider.validate mock should not be called")
    end

    it 'should not send validation results for documents that do not exist' do
      expect(PuppetLanguageServer::ValidationQueue).to_not receive(:send_diagnostics)

      subject.validate_sync(MISSING_FILENAME, 1, connection_id)
    end

    context 'for a puppet manifest file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:validate).with(FILE_CONTENT, Hash).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", MANIFEST_FILENAME, FILE_CONTENT, validation_result
    end

    context 'for a Puppetfile file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Puppetfile::ValidationProvider).to receive(:validate).with(FILE_CONTENT).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", PUPPETFILE_FILENAME, FILE_CONTENT, validation_result
    end

    context 'for an EPP template file' do
      validation_result = [{ 'result' => 'MockResult' }]

      before(:each) do
        expect(PuppetLanguageServer::Epp::ValidationProvider).to receive(:validate).with(FILE_CONTENT).and_return(validation_result)
      end

      it_should_behave_like "document which sends validation results", EPP_FILENAME, FILE_CONTENT, validation_result
    end

    context 'for an unknown file' do
      validation_result = []

      it_should_behave_like "document which sends validation results", UNKNOWN_FILENAME, FILE_CONTENT, validation_result
    end
  end

  describe '#documents' do
    it 'should respond to documents method' do
      expect(subject).to respond_to(:documents)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'tempfile'
require 'puppet-languageserver/crash_dump'

describe 'PuppetLanguageServer::CrashDump' do
  describe '.default_crash_file' do
    it 'returns a String' do
      expect(PuppetLanguageServer::CrashDump.default_crash_file).to be_a(String)
    end

    it 'returns a path in the system temp directory' do
      expect(PuppetLanguageServer::CrashDump.default_crash_file).to include(Dir.tmpdir)
    end

    it 'includes a descriptive filename' do
      result = PuppetLanguageServer::CrashDump.default_crash_file
      expect(result).to include('puppet_language_server_crash')
    end
  end

  describe '.write_crash_file' do
    let(:mock_error) do
      raise 'test crash error'
    rescue StandardError => e
      e
    end

    # rubocop:disable RSpec/VerifiedDoubles
    let(:mock_documents) do
      double('documents',
             document_uris: [],
             document_content: nil)
    end

    let(:session_state) do
      double('session_state', documents: mock_documents)
    end
    # rubocop:enable RSpec/VerifiedDoubles

    let(:crash_file) { Tempfile.new(['crash_test', '.txt']) }

    after { crash_file.unlink }

    it 'writes a crash file to the given path' do
      PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path)
      expect(File.size(crash_file.path)).to be > 0
    end

    it 'includes the error message in the crash file' do
      PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path)
      content = File.read(crash_file.path)
      expect(content).to include('test crash error')
    end

    it 'includes a backtrace in the crash file' do
      PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path)
      content = File.read(crash_file.path)
      expect(content).to include('Backtrace')
    end

    it 'uses the default crash file path when none is provided' do
      default_path = PuppetLanguageServer::CrashDump.default_crash_file
      PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state)
      expect(File.exist?(default_path)).to be(true)
    ensure
      FileUtils.rm_f(default_path)
    end

    context 'with documents in the session state' do
      # rubocop:disable RSpec/VerifiedDoubles
      let(:mock_documents) do
        double('documents',
               document_uris: ['file:///example.pp'],
               document_content: "class example {}\n")
      end
      # rubocop:enable RSpec/VerifiedDoubles

      it 'includes the document URI in the crash file' do
        PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path)
        expect(File.read(crash_file.path)).to include('file:///example.pp')
      end

      it 'includes the document content in the crash file' do
        PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path)
        expect(File.read(crash_file.path)).to include('class example {}')
      end
    end

    context 'with additional objects' do
      let(:extra_objects) { { 'Extra Info' => 'some additional data' } }

      it 'includes the extra key in the crash file' do
        PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path, extra_objects)
        expect(File.read(crash_file.path)).to include('Extra Info')
      end

      it 'includes the extra value in the crash file' do
        PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, crash_file.path, extra_objects)
        expect(File.read(crash_file.path)).to include('some additional data')
      end
    end

    context 'when writing fails' do
      it 'does not raise an error' do
        expect do
          PuppetLanguageServer::CrashDump.write_crash_file(mock_error, session_state, '/no/such/dir/crash.txt')
        end.not_to raise_error
      end
    end
  end
end

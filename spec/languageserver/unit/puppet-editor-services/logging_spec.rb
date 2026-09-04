# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'tempfile'
require 'puppet_editor_services/logging'

describe 'PuppetEditorServices logging' do
  around do |example|
    saved_logger   = PuppetEditorServices.instance_variable_get(:@logger)
    saved_log_file = PuppetEditorServices.instance_variable_get(:@log_file)
    example.run
  ensure
    # Close any real file opened during the test before restoring state.
    # Use is_a?(IO) to avoid touching RSpec doubles, which expire before ensure runs.
    current_log_file = PuppetEditorServices.instance_variable_get(:@log_file)
    current_log_file.close if current_log_file.is_a?(IO) && !current_log_file.closed?
    PuppetEditorServices.instance_variable_set(:@logger,   saved_logger)
    PuppetEditorServices.instance_variable_set(:@log_file, saved_log_file)
  end

  describe '.log_message' do
    context 'when no logger is configured' do
      before { PuppetEditorServices.instance_variable_set(:@logger, nil) }

      it 'does not raise an error' do
        expect { PuppetEditorServices.log_message(:info, 'test') }.not_to raise_error
      end

      it 'returns nil' do
        expect(PuppetEditorServices.log_message(:debug, 'test')).to be_nil
      end
    end

    context 'when a logger is configured' do
      let(:mock_logger) { instance_double(Logger) }

      before do
        PuppetEditorServices.instance_variable_set(:@logger,   mock_logger)
        PuppetEditorServices.instance_variable_set(:@log_file, nil)
      end

      it 'calls debug on the logger for :debug severity' do
        expect(mock_logger).to receive(:debug).with('debug message')
        PuppetEditorServices.log_message(:debug, 'debug message')
      end

      it 'calls info on the logger for :info severity' do
        expect(mock_logger).to receive(:info).with('info message')
        PuppetEditorServices.log_message(:info, 'info message')
      end

      it 'calls warn on the logger for :warn severity' do
        expect(mock_logger).to receive(:warn).with('warn message')
        PuppetEditorServices.log_message(:warn, 'warn message')
      end

      it 'calls error on the logger for :error severity' do
        expect(mock_logger).to receive(:error).with('error message')
        PuppetEditorServices.log_message(:error, 'error message')
      end

      it 'calls fatal on the logger for :fatal severity' do
        expect(mock_logger).to receive(:fatal).with('fatal message')
        PuppetEditorServices.log_message(:fatal, 'fatal message')
      end

      it 'calls unknown on the logger for an unrecognised severity' do
        expect(mock_logger).to receive(:unknown).with('other message')
        PuppetEditorServices.log_message(:something_else, 'other message')
      end
    end

    context 'when a log file is also configured' do
      let(:mock_logger)   { instance_double(Logger) }
      let(:mock_log_file) { instance_double(File) }

      before do
        PuppetEditorServices.instance_variable_set(:@logger,   mock_logger)
        PuppetEditorServices.instance_variable_set(:@log_file, mock_log_file)
        allow(mock_logger).to receive(:info)
      end

      it 'fsyncs the log file after each message' do
        expect(mock_log_file).to receive(:fsync)
        PuppetEditorServices.log_message(:info, 'test')
      end
    end
  end

  describe '.init_logging' do
    context 'when debug option is nil' do
      it 'sets the logger to nil' do
        PuppetEditorServices.init_logging({ debug: nil })
        expect(PuppetEditorServices.instance_variable_get(:@logger)).to be_nil
      end
    end

    context 'when debug option is stdout' do
      it 'creates a Logger that writes to $stdout' do
        PuppetEditorServices.init_logging({ debug: 'stdout' })
        expect(PuppetEditorServices.instance_variable_get(:@logger)).to be_a(Logger)
      end

      it 'is case-insensitive (STDOUT)' do
        PuppetEditorServices.init_logging({ debug: 'STDOUT' })
        expect(PuppetEditorServices.instance_variable_get(:@logger)).to be_a(Logger)
      end
    end

    context 'when debug option is a file path' do
      let(:log_file) { Tempfile.new(['puppet_ls_test_log', '.log']) }

      after { log_file.unlink }

      it 'creates a Logger backed by the file' do
        PuppetEditorServices.init_logging({ debug: log_file.path })
        expect(PuppetEditorServices.instance_variable_get(:@logger)).to be_a(Logger)
        expect(PuppetEditorServices.instance_variable_get(:@log_file)).not_to be_nil
      end
    end

    context 'when debug option is an invalid file path' do
      it 'disables logging and does not raise' do
        expect { PuppetEditorServices.init_logging({ debug: '/no/such/dir/log.txt' }) }.not_to raise_error
        expect(PuppetEditorServices.instance_variable_get(:@logger)).to be_nil
      end
    end
  end
end

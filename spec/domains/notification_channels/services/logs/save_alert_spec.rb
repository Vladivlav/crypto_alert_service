require 'rails_helper'
require 'dry/monads'

# Создаем простую структуру, чтобы имитировать модель Channel
class MockChannel < OpenStruct
end

module NotificationChannels
  RSpec.describe Services::Logs::SaveAlert do
    include Dry::Monads[:result]

    let(:temp_log_dir) { Rails.root.join('tmp', 'test_log_channels') }
    let(:test_filename) { 'custom_alert.log' }
    let(:full_file_path) { temp_log_dir.join(test_filename).to_s }
    let(:test_message) { "Тестовое сообщение об ошибке для записи." }

    let(:channel) { MockChannel.new(logs_filename: test_filename) }

    subject(:call) { described_class.new.call(channel: channel, message_text: test_message) }

    before do
      stub_const("#{described_class}::CHANNEL_LOGS_DIR", temp_log_dir)
      FileUtils.mkdir_p(temp_log_dir) unless Dir.exist?(temp_log_dir)
    end

    after { FileUtils.rm_rf(temp_log_dir) }

    context 'when the file is successfully written' do
      it 'returns Success with the full file path' do
        expect(call).to be_success
        expect(call.value!).to eq full_file_path
      end

      it 'appends the formatted log entry to the file' do
        call

        expect(File.exist?(full_file_path)).to be true

        content = File.read(full_file_path)
        expect(content).to include(test_message)

        expect(content).to match(/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] #{Regexp.escape(test_message)}\n$/)
      end
    end

    context 'when channel.logs_filename is nil' do
      let(:channel) { MockChannel.new(logs_filename: nil) }

      it 'returns Failure(:missing_logs_filename)' do
        expect(call).to be_failure
        expect(call.failure).to eq :missing_logs_filename
      end
    end

    context 'when an I/O error occurs during file operation' do
      before do
        allow(File).to receive(:open).and_raise(Errno::EACCES.new('Permission denied'))
      end

      it 'returns Failure with the specific file I/O error symbol' do
        expect(call).to be_failure
        expect(call.failure).to eq "file_io_error_errno/eacces"
      end
    end

    context 'when an unexpected StandardError occurs' do
      before do
        allow(File).to receive(:open).and_raise(RuntimeError.new('Database connection dropped unexpectedly'))
      end

      it 'returns Failure with the critical error symbol' do
        expect(call).to be_failure
        expect(call.failure).to eq "critical_error_runtime_error"
      end
    end
  end
end

# spec/services/add_telegram_channel_service_spec.rb
require 'rails_helper'
require 'dry/monads'

module NotificationChannels
  RSpec.describe Scenarios::CreateLogsChannel do
    include Dry::Monads[:result]

    subject(:call) do
      described_class.new(**dependencies).call(file_name: filename)
    end
    let(:filename) { "filename" }

    let(:filename_guard) { instance_double(Services::Logs::CheckFileExist) }
    let(:channel_model)  { class_double(NotificationChannel).as_stubbed_const }
    let(:dependencies)   { { filename_guard: filename_guard, channel_model: channel_model } }
    let(:mocked_channel) { instance_double(NotificationChannel) }

    let(:expected_create_args) do
      {
        channel_type: 'text_logs',
        config: { file_name: filename },
        is_active: true
      }
    end

    context "when filename already exists" do
      before do
        allow(filename_guard).to receive(:call).with(filename).and_return(Failure(:error))
      end

      it "fails with an error" do
        expect(call).to be_failure
      end

      it "does not create a channel" do
        expect(channel_model).not_to receive(:create)
        call
      end
    end

    context "when filename does not exists" do
      before do
        allow(filename_guard).to receive(:call).with(filename).and_return(Success("filepath"))
      end

      context "when channel saved successfully" do
        before do
          allow(channel_model).to receive(:create).with(expected_create_args).and_return(mocked_channel)
          allow(mocked_channel).to receive(:persisted?).and_return(true)
        end

        it "finish the scenario successfully" do
          expect(call).to be_success
          expect(call.value!).to be mocked_channel
        end

        it "saves a channel into DB" do
          expect(channel_model).to receive(:create)
          call
        end
      end

      context "when error occured during channel save into DB" do
        before do
          allow(channel_model).to receive(:create).with(expected_create_args).and_return(mocked_channel)
          allow(mocked_channel).to receive(:persisted?).and_return(false)
        end

        it "fails with an error" do
          expect(call).to be_failure
          expect(call.failure).to eq "Failed to create channel record."
        end
      end
    end
  end
end

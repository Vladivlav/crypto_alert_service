# spec/domains/notification_channels/scenarios/deactivate_channel_spec.rb

require 'rails_helper'
require 'dry/monads'

module NotificationChannels
  RSpec.describe Services::Disable, type: :service do
    include Dry::Monads[:result]

    let(:channel) { create(:notification_channel, is_active: true) }

    describe '#call' do
      context 'when save is succesfull' do
        it 'disable notification channel' do
          result = described_class.new.call(channel)

          channel.reload
          expect(channel.is_active).to eq(false)
          expect(result).to be_success
        end

        it 'return success result with the channel' do
          result = described_class.new.call(channel)
          expect(result).to be_success
          expect(result.value!).to eq(channel)
        end
      end

      context 'when save have failed' do
        let(:error_message) { 'validation failed' }

        before do
          allow(channel).to receive(:save).and_return(false)
          allow(channel).to receive_message_chain(:errors, :full_messages, :join).and_return(error_message)
        end

        it 'respond with a failure and an error message' do
          result = described_class.new.call(channel)
          expect(result).to be_failure
          expect(result.failure).to include("Failed to deactivate channel ID #{channel.id}: #{error_message}")
        end

        it 'does not change the channel status' do
          # Вызываем сервис, чтобы он попытался обновить канал
          described_class.new.call(channel)

          # Перезагружаем канал, чтобы убедиться, что никаких изменений в БД не сохранилось
          channel.reload
          expect(channel.is_active).to eq(true)
        end
      end
    end
  end
end

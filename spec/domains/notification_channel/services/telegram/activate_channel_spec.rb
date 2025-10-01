# spec/domains/notification_channel/services/telegram/activate_channel_spec.rb

require 'rails_helper'
require 'dry/monads'

module NotificationChannels
  RSpec.describe Services::Telegram::ActivateChannel, type: :service do
    include Dry::Monads[:result]

    let(:channel) { create(:notification_channel, is_active: false, config: { 'chat_id' => nil }) }
    let(:chat_id) { '123456789' }

    describe '#call' do
      context 'when successful' do
        it 'updates the channel with is_active: true and a new chat_id' do
          result = described_class.call(channel: channel, chat_id: chat_id)

          # Перезагружаем канал, чтобы получить актуальные данные из БД
          channel.reload

          expect(channel.is_active).to eq(true)
          expect(channel.chat_id).to eq(chat_id)
          expect(result).to be_success
        end

        it 'returns a successful result' do
          result = described_class.call(channel: channel, chat_id: chat_id)
          expect(result).to be_success
          expect(result.value!).to eq(channel)
        end
      end

      context 'when saving the channel fails' do
        before do
          allow(channel).to receive(:save).and_return(false)
          allow(channel).to receive_message_chain(:errors, :full_messages, :join).and_return('validation error')
        end

        it 'returns a failure result with an error message' do
          result = described_class.call(channel: channel, chat_id: chat_id)
          expect(result).to be_failure
          expect(result.failure).to include("Failed to activate channel ID #{channel.id}: validation error")
        end

        it 'does not change the channel status' do
          original_active_status = channel.is_active
          original_chat_id = channel.chat_id

          described_class.call(channel: channel, chat_id: chat_id)

          # Перезагружаем канал, чтобы проверить, что никаких изменений не сохранилось
          channel.reload

          expect(channel.is_active).to eq(original_active_status)
          expect(channel.chat_id).to eq(original_chat_id)
        end
      end
    end
  end
end

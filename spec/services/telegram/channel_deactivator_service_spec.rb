# spec/services/telegram/channel_deactivator_service_spec.rb
require 'rails_helper'
require 'dry/monads'

RSpec.describe Telegram::ChannelDeactivatorService, type: :service do
  include Dry::Monads[:result]

  let(:channel) { create(:notification_channel, is_active: true) }

  describe '#call' do
    context 'когда сохранение успешно' do
      it 'устанавливает статус канала на false' do
        result = described_class.call(channel: channel)

        # Перезагружаем канал, чтобы получить актуальные данные из БД
        channel.reload
        expect(channel.is_active).to eq(false)
        expect(result).to be_success
      end

      it 'возвращает успешный результат с объектом канала' do
        result = described_class.call(channel: channel)
        expect(result).to be_success
        # Правильная проверка: ожидаем, что результат будет тем же объектом канала
        expect(result.value!).to eq(channel)
      end
    end

    context 'когда сохранение канала проваливается' do
      let(:error_message) { 'validation failed' }

      before do
        allow(channel).to receive(:save).and_return(false)
        allow(channel).to receive_message_chain(:errors, :full_messages, :join).and_return(error_message)
      end

      it 'возвращает ошибку и текст сообщения' do
        result = described_class.call(channel: channel)
        expect(result).to be_failure
        expect(result.failure).to include("Failed to deactivate channel ID #{channel.id}: #{error_message}")
      end

      it 'не меняет статус канала' do
        # Вызываем сервис, чтобы он попытался обновить канал
        described_class.call(channel: channel)

        # Перезагружаем канал, чтобы убедиться, что никаких изменений в БД не сохранилось
        channel.reload
        expect(channel.is_active).to eq(true)
      end
    end
  end
end

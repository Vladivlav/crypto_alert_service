# spec/services/telegram_message_processor_spec.rb
require 'rails_helper'
require 'dry/monads'

RSpec.describe TelegramMessageProcessor, type: :service do
  include Dry::Monads[:result]

  let(:channel) { instance_double('NotificationChannel', id: 1) }
  let(:activator_service) { class_double('Telegram::ChannelActivatorService') }
  let(:deactivator_service) { class_double('Telegram::ChannelDeactivatorService') }

  # Создаем экземпляр сервиса с моками
  subject(:processor) { described_class.new(activator_service: activator_service, deactivator_service: deactivator_service) }

  describe '#call' do
    let(:chat_id) { 123456 }

    context 'when received message does not contain ChatId' do
      let(:message) { { 'text' => '/start', 'chat' => { 'id' => nil } } }

      it 'returns a failure with an error message' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_failure
        expect(result.failure).to eq('No Chat ID found.')
      end
    end

    context 'when message is a command to start the bot' do
      let(:message) { { 'text' => '/start', 'chat' => { 'id' => chat_id } } }

      before do
        allow(activator_service).to receive(:call).and_return(Success('activated'))
      end

      it 'checks bot token for validity' do
        processor.call(channel: channel, message: message)
        expect(activator_service).to have_received(:call).with(channel: channel, chat_id: chat_id.to_s)
      end

      it 'returns a success with a message from Telegram API response' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
        expect(result.value!).to eq('activated')
      end
    end

    context 'when message is a command to stop the bot' do
      let(:message) { { 'text' => '/stop', 'chat' => { 'id' => chat_id } } }

      before do
        allow(deactivator_service).to receive(:call).and_return(Success('deactivated'))
      end

      it 'deactivates the notification channel' do
        processor.call(channel: channel, message: message)
        expect(deactivator_service).to have_received(:call).with(channel: channel)
      end

      it 'returns a success with a message' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
        expect(result.value!).to eq('deactivated')
      end
    end

    context 'when message has an empty text' do
      let(:message) { { 'text' => nil, 'chat' => { 'id' => chat_id } } }

      it 'returns a success' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
      end

      it 'does not change the status of the channel' do
        expect(activator_service).to_not receive(:call)
        expect(deactivator_service).to_not receive(:call)
        processor.call(channel: channel, message: message)
      end
    end

    context 'when message is not a command to start of to finish' do
      let(:message) { { 'text' => 'Random text', 'chat' => { 'id' => chat_id } } }

      it 'returns a success' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
      end

      it 'does not change the status of the channel' do
        expect(activator_service).to_not receive(:call)
        expect(deactivator_service).to_not receive(:call)
        processor.call(channel: channel, message: message)
      end
    end
  end
end

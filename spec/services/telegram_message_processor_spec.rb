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

    context 'когда сообщение не содержит chat ID' do
      let(:message) { { 'text' => '/start', 'chat' => { 'id' => nil } } }

      it 'возвращает Failure с соответствующим сообщением' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_failure
        expect(result.failure).to eq('No Chat ID found.')
      end
    end

    context 'когда сообщение содержит команду /start' do
      let(:message) { { 'text' => '/start', 'chat' => { 'id' => chat_id } } }

      before do
        allow(activator_service).to receive(:call).and_return(Success('activated'))
      end

      it 'вызывает сервис активации с правильными аргументами' do
        processor.call(channel: channel, message: message)
        expect(activator_service).to have_received(:call).with(channel: channel, chat_id: chat_id.to_s)
      end

      it 'возвращает результат от сервиса активации' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
        expect(result.value!).to eq('activated')
      end
    end

    context 'когда сообщение содержит команду /stop' do
      let(:message) { { 'text' => '/stop', 'chat' => { 'id' => chat_id } } }

      before do
        allow(deactivator_service).to receive(:call).and_return(Success('deactivated'))
      end

      it 'вызывает сервис деактивации с правильными аргументами' do
        processor.call(channel: channel, message: message)
        expect(deactivator_service).to have_received(:call).with(channel: channel)
      end

      it 'возвращает результат от сервиса деактивации' do
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
        expect(result.value!).to eq('deactivated')
      end
    end

    context 'когда текст сообщения пустой' do
      let(:message) { { 'text' => nil, 'chat' => { 'id' => chat_id } } }

      it 'возвращает Success() и не вызывает никакие сервисы' do
        expect(activator_service).to_not receive(:call)
        expect(deactivator_service).to_not receive(:call)
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
      end
    end

    context 'когда текст сообщения случайный' do
      let(:message) { { 'text' => 'Random text', 'chat' => { 'id' => chat_id } } }

      it 'возвращает Success() и не вызывает никакие сервисы' do
        expect(activator_service).to_not receive(:call)
        expect(deactivator_service).to_not receive(:call)
        result = processor.call(channel: channel, message: message)
        expect(result).to be_success
      end
    end
  end
end

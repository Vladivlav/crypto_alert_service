require 'rails_helper'
require 'dry/monads'
require 'json'

module NotificationChannels
  RSpec.describe Services::Telegram::SendMessage do
    include Dry::Monads[:result]

    # --- Моки Зависимостей ---
    let(:message_text) { 'Тестовое сообщение об алерте.' }

    # Мок объекта Канала
    let(:channel) {
      instance_double(
        'NotificationChannel',
        id: 99,
        bot_token: 'valid_token',
        chat_id: 12345
      )
    }

    # Мок Клиента Telegram API (класс)
    let(:telegram_client_class) { class_double('ExternalApis::TelegramClient') }
    # Мок инстанса Клиента Telegram API
    let(:telegram_client) { instance_double('ExternalApis::TelegramClient') }

    # Мок Сервиса Деактивации
    let(:channel_disabler) { instance_double(Services::Disable, call: Success()) }

    # Создаем экземпляр сервиса с инжектированными моками
    subject(:service) do
      described_class.new(
        client_class: telegram_client_class,
        channel_disabler: channel_disabler
      )
    end

    # --- Общая проверка: ensure ---
    # Проверяем, что деактивация канала вызывается в любом случае
    after do
      # Убеждаемся, что disabler всегда вызывается
      expect(channel_disabler).to have_received(:call).with(channel).once
    end


    # =========================================================================
    # 1. СЦЕНАРИИ РАННЕГО ВЫХОДА
    # =========================================================================

    context 'when channel is missing required credentials (nil)' do
      # Переопределяем channel для этого контекста
      let(:channel) {
        instance_double(
          'NotificationChannel',
          id: 99,
          bot_token: nil, # Не хватает токена
          chat_id: 12345
        )
      }

      # Важно: Воркеры не должны вызываться
      before do
        allow(telegram_client_class).to receive(:new).with(any_args)
        allow(channel_disabler).to receive(:call).and_return(Success())
      end

      it 'returns Failure(:missing_credentials) immediately and does not call client' do
        # Проверяем, что клиент API не был инициализирован
        expect(telegram_client_class).not_to receive(:new)

        # Результат должен быть Failure
        result = service.call(channel: channel, message_text: message_text)
        expect(result).to eq(Failure(:missing_credentials))
      end

      # NOTE: ensure (after block) гарантирует вызов disabler
    end


    # =========================================================================
    # 2. СЦЕНАРИИ УСПЕХА И ОШИБКИ API (HTTP 200)
    # =========================================================================

    context 'when API call returns HTTP 200' do
      before do
        # Имитируем успешную инициализацию клиента
        allow(telegram_client_class).to receive(:new).and_return(telegram_client)
        # Мокаем метод send_message для возврата мока ответа
        allow(telegram_client).to receive(:send_message).and_return(response)
      end

      context 'when Telegram API indicates success (ok: true)' do
        let(:response_body) { { 'ok' => true, 'result' => { 'message_id' => 42 } }.to_json }
        let(:response) { instance_double('Faraday::Response', status: 200, body: response_body) }

        it 'returns Success(:sent_successfully)' do
          result = service.call(channel: channel, message_text: message_text)
          expect(result).to eq(Success(:sent_successfully))
        end
      end

      context 'when Telegram API indicates failure (ok: false)' do
        let(:error_desc) { 'chat not found' }
        let(:response_body) { { 'ok' => false, 'error_code' => 404, 'description' => error_desc }.to_json }
        let(:response) { instance_double('Faraday::Response', status: 200, body: response_body) }

        it 'returns Failure with descriptive telegram_api_error symbol' do
          result = service.call(channel: channel, message_text: message_text)
          expected_failure = Failure(:telegram_api_error_chat_not_found)
          expect(result).to eq(expected_failure)
        end
      end

      context 'when JSON is invalid (JSON::ParserError)' do
        let(:response_body) { '{"ok": true, "result": 42' } # Невалидный JSON
        let(:response) { instance_double('Faraday::Response', status: 200, body: response_body) }

        it 'returns Failure(:json_parse_error)' do
          result = service.call(channel: channel, message_text: message_text)
          expect(result).to eq(Failure(:json_parse_error))
        end
      end
    end


    # =========================================================================
    # 3. СЦЕНАРИИ КРИТИЧЕСКИХ ОШИБОК (Non-HTTP 200 / Сеть)
    # =========================================================================

    context 'when API call returns non-200 HTTP status' do
      let(:response) { instance_double('Faraday::Response', status: 401, body: 'Unauthorized') }

      before do
        allow(telegram_client_class).to receive(:new).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_return(response)
      end

      it 'returns Failure with http_error symbol' do
        result = service.call(channel: channel, message_text: message_text)
        expect(result).to eq(Failure(:http_error_401))
      end
    end

    context 'when a StandardError occurs during client communication (network failure)' do
      before do
        allow(telegram_client_class).to receive(:new).and_return(telegram_client)
        # Имитируем сетевую ошибку (e.g., Faraday::ConnectionFailed)
        allow(telegram_client).to receive(:send_message).and_raise(IOError, "Connection refused")
      end

      it 'returns Failure with critical_error symbol based on exception class' do
        result = service.call(channel: channel, message_text: message_text)
        # Ожидаем: critical_error_io_error (из-за .underscore)
        expect(result).to eq(Failure(:critical_error_io_error))
      end
    end
  end
end

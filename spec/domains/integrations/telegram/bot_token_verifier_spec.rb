# spec/services/telegram_validator_service_spec.rb

require 'rails_helper'
require 'webmock/rspec'

module Integrations
  RSpec.describe Telegram::BotTokenVerifier, type: :service do
    let(:valid_token) { "123456:ABC-DEF1234ghIkl-789" }
    let(:invalid_token) { "invalid_token" }

    it 'returns a success with valid token' do
      # Заглушаем HTTP-запрос к Telegram, чтобы имитировать успешный ответ
      stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
        to_return(status: 200, body: '{"ok":true, "result":{}}', headers: {})

      service = described_class.new
      expect(service.call(valid_token)).to be_success
    end

    it 'returns a failure for invalid token' do
      stub_request(:get, "https://api.telegram.org/bot#{invalid_token}/getMe").
        to_return(status: 401, body: '{"ok":false}', headers: {})

      service = described_class.new
      expect(service.call(invalid_token)).to be_failure
    end

    it 'returns a failure if TG server respond with 500 http code' do
      stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
        to_return(status: 500)

      service = described_class.new
      expect(service.call(valid_token)).to be_failure
    end

    it 'returns a failure if server respond with invalid JSON response' do
      stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
        to_return(status: 200, body: '{"ok":true, "result":{', headers: {})

      service = described_class.new
      expect(service.call(valid_token)).to be_failure
    end

    it 'returns a failure on a network error' do
      stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
        to_raise(Net::ReadTimeout)

      service = described_class.new
      expect(service.call(valid_token)).to be_failure
    end
  end
end

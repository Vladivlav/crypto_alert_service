# spec/services/telegram_validator_service_spec.rb

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe TelegramValidator, type: :service do
  let(:valid_token) { "123456:ABC-DEF1234ghIkl-789" }
  let(:invalid_token) { "invalid_token" }

  it 'возвращает true для валидного токена' do
    # Заглушаем HTTP-запрос к Telegram, чтобы имитировать успешный ответ
    stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
      to_return(status: 200, body: '{"ok":true, "result":{}}', headers: {})

    service = described_class.new
    expect(service.call(valid_token)).to be_success
  end

  it 'возвращает false для невалидного токена' do
    # Заглушаем HTTP-запрос к Telegram, чтобы имитировать ошибку
    stub_request(:get, "https://api.telegram.org/bot#{invalid_token}/getMe").
      to_return(status: 401, body: '{"ok":false}', headers: {})

    service = described_class.new
    expect(service.call(invalid_token)).to be_failure
  end

  it 'возвращает false, если сервер вернул ошибку 500' do
    stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
      to_return(status: 500)

    service = described_class.new
    expect(service.call(valid_token)).to be_failure
  end

  it 'возвращает false, если ответ сервера не является валидным JSON' do
    stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
      to_return(status: 200, body: '{"ok":true, "result":{', headers: {})

    service = described_class.new
    expect(service.call(valid_token)).to be_failure
  end

  it 'возвращает false при ошибке сети (например, таймаут)' do
    stub_request(:get, "https://api.telegram.org/bot#{valid_token}/getMe").
      to_raise(Net::ReadTimeout)

    service = described_class.new
    expect(service.call(valid_token)).to be_failure
  end
end

# spec/services/telegram_webhook_spec.rb

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe NotificationChannels::Webhooks::Telegram, type: :service do
  # Создаём заглушку для объекта channel
  let(:channel) do
    instance_double(
      NotificationChannel,
      id: 123,
      config: { "token" => "123456:ABC-DEF1234ghIkl-789" },
      webhook_token: "o217J5k9fS"
    )
  end
  let(:app_host) { "example.com" }
  let(:webhook_url) { "http://#{app_host}/api/v1/telegram/webhook/o217J5k9fS" }

  # Настраиваем Rails для работы в тесте
  before do
    WebMock.reset!
    allow(Rails.application.credentials).to receive(:app_host).and_return(app_host)
  end

  context "when Telegram API responds successfully" do
    it 'returns a success object' do
      stub_request(:post, "https://api.telegram.org/bot#{channel.config['token']}/setWebhook")
        .with(body: { url: webhook_url }) # Match the form-urlencoded body
        .to_return(status: 200, body: '{"ok":true, "result":{}}', headers: {})

      service = described_class.new
      expect(service.call(channel)).to be_success
    end
  end

  context "when Telegram API returns an error" do
    it 'returns a failure' do
      stub_request(:post, "https://api.telegram.org/bot#{channel.config['token']}/setWebhook")
        .to_return(status: 404, body: '{"ok":false}', headers: {})

      service = described_class.new
      expect(service.call(channel)).to be_failure
    end
  end

  context "when request to Telegram API raises a network error" do
    before do
      stub_request(:post, "https://api.telegram.org/bot#{channel.config['token']}/setWebhook")
        .to_raise(Faraday::ConnectionFailed)
    end

    it 'returns a failure' do
      expect(described_class.new.call(channel)).to be_failure
    end
  end
end

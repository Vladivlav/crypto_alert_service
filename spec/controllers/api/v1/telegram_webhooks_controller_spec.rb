# spec/controllers/api/v1/telegram_webhooks_controller_spec.rb
require 'rails_helper'
require 'dry/monads'

RSpec.describe Api::V1::TelegramWebhooksController, type: :controller do
  let(:channel) { create(:notification_channel) }
  let(:telegram_message_processor) { class_double('TelegramMessageProcessor') }

  before do
    stub_const('TelegramMessageProcessor', telegram_message_processor)
    allow(telegram_message_processor).to receive(:call).and_return(Dry::Monads::Success())
    # Мокаем find_by_webhook_token, чтобы не зависеть от реального токена
    allow(NotificationChannel).to receive(:find_by_webhook_token).and_return(channel)
  end

  describe "POST receive" do
    let(:base_payload) do
      {
        'message' => {
          'text' => 'some_text',
          'chat' => {
            'id' => '123456789'
          }
        }
      }
    end

    context "when a webhook is received with a valid token" do
      context "with a /start command" do
        it "calls TelegramMessageProcessor with the correct arguments" do
          payload = base_payload.merge('message' => { 'text' => '/start' })
          post :receive, params: payload.merge(webhook_token: channel.webhook_token), as: :json
          expect(telegram_message_processor).to have_received(:call).with(channel: channel, message: payload['message'])
        end
      end

      context "with a /stop command" do
        it "calls TelegramMessageProcessor with the correct arguments" do
          payload = base_payload.merge('message' => { 'text' => '/stop' })
          post :receive, params: payload.merge(webhook_token: channel.webhook_token), as: :json
          expect(telegram_message_processor).to have_received(:call).with(channel: channel, message: payload['message'])
        end
      end

      context "with a random message" do
        it "calls TelegramMessageProcessor with the correct arguments" do
          payload = base_payload.merge('message' => { 'text' => 'random text' })
          post :receive, params: payload.merge(webhook_token: channel.webhook_token), as: :json
          expect(telegram_message_processor).to have_received(:call).with(channel: channel, message: payload['message'])
        end
      end

      it "responds with a 200 OK status" do
        payload = base_payload.merge('message' => { 'text' => '/start' })
        post :receive, params: payload.merge(webhook_token: channel.webhook_token), as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "when a webhook is received with an unknown token" do
      before do
        allow(NotificationChannel).to receive(:find_by_webhook_token).and_return(nil)
      end

      it "does not call TelegramMessageProcessor and responds with a 404 Not Found" do
        expect(telegram_message_processor).not_to receive(:call)
        post :receive, params: base_payload.merge(webhook_token: 'invalid-token'), as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

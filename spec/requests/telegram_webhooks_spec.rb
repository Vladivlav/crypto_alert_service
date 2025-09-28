# spec/requests/api/v1/telegram_webhooks_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::TelegramWebhooks", type: :request do
  let(:channel) { create(:notification_channel) }
  let(:webhook_url) { "/api/v1/telegram/webhook/#{channel.webhook_token}" }

  let(:base_telegram_payload) do
    {
      "message" => {
        "text" => "some_text",
        "chat" => {
          "id" => "123456789"
        }
      }
    }
  end

  describe "POST /api/v1/telegram_webhooks/:webhook_token" do
    context "когда приходит команда /start" do
      let(:payload) do
        {
          telegram_webhook: base_telegram_payload.merge("message" => { "text" => "/start", "chat" => { "id" => "start_chat_id" } })
        }
      end

      it "активирует канал и сохраняет chat_id" do
        channel.update!(is_active: false, config: { 'chat_id' => nil })

        expect { post webhook_url, params: payload, as: :json }.to change { channel.reload.is_active }.from(false).to(true)
        expect(channel.reload.chat_id).to eq("start_chat_id")

        expect(response).to have_http_status(:ok)
      end
    end

    context "когда приходит команда /stop" do
      let(:payload) do
        {
          telegram_webhook: base_telegram_payload.merge("message" => { "text" => "/stop", "chat" => { "id" => "stop_chat_id" } })
        }
      end

      it "деактивирует канал, но не меняет chat_id" do
        channel.update!(is_active: true, config: { 'chat_id' => 'existing_chat_id' })

        expect { post webhook_url, params: payload, as: :json }.to change { channel.reload.is_active }.from(true).to(false)
        expect(channel.reload.chat_id).to eq("existing_chat_id")

        expect(response).to have_http_status(:ok)
      end
    end

    context "когда приходит случайный текст" do
      let(:payload) do
        {
          telegram_webhook: base_telegram_payload.merge("message" => { "text" => "Random text", "chat" => { "id" => "random_chat_id" } })
        }
      end
      it "не меняет статус канала и chat_id" do
        channel.update!(is_active: false, config: { 'chat_id' => 'existing_chat_id' })

        expect { post webhook_url, params: payload, as: :json }.to_not change { channel.reload.is_active }
        expect(channel.reload.chat_id).to eq("existing_chat_id")

        expect(response).to have_http_status(:ok)
      end
    end

    context "когда токен не найден" do
      let(:invalid_url) { "/api/v1/telegram_webhooks/invalid_token" }

      it "возвращает статус 404 Not Found" do
        post invalid_url, params: base_telegram_payload, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

# spec/requests/channels_spec.rb
require 'rails_helper'
require "webmock/rspec"

RSpec.describe "Channels", type: :request do
  describe "POST /api/v1/channels/:channel_type" do
    let(:telegram_api_url) { "https://api.telegram.org" }
    let(:valid_telegram_token) { "1234567890:AABB-ccdd_EEFFGG-hhIijjKkL-MNNN" }

    # Правильный формат параметров, как они приходят от клиента
    let(:valid_params) do
      {
        channel: {
          config: {
            token: valid_telegram_token
          }
        }
      }
    end

    # Заглушка для внешних запросов к Telegram API
    before do
      # 1. Заглушка для проверки токена (getMe)
      stub_request(:get, "#{telegram_api_url}/bot#{valid_telegram_token}/getMe").
        to_return(
          status: 200,
          body: {
            ok: true,
            result: { id: 12345, is_bot: true, first_name: "TestBot" }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # 2. Заглушка для установки вебхука (setWebhook)
      stub_request(:post, "#{telegram_api_url}/bot#{valid_telegram_token}/setWebhook").
        to_return(
          status: 200,
          body: {
            ok: true,
            result: true
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context "when input is valid (happy path)" do
      it "creates a new channel and returns a 201 status" do
        expect {
          post "/api/v1/channels/telegram", params: valid_params, as: :json
        }.to change(NotificationChannel, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Channel created successfully")
        expect(json_response['channel']['config']['token']).to eq(valid_telegram_token)
      end
    end

    context "when input is valid (happy path)" do
      # 1. Проверяем, что создается запись в БД
      it "creates a new channel record" do
        expect {
          post "/api/v1/channels/telegram", params: valid_params, as: :json
        }.to change(NotificationChannel, :count).by(1)
      end

      # 2. Проверяем HTTP-статус
      it "returns a 201 Created status" do
        post "/api/v1/channels/telegram", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end

      # 3. Проверяем, что ответ содержит правильное сообщение
      it "returns a success message in the JSON response" do
        post "/api/v1/channels/telegram", params: valid_params, as: :json
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Channel created successfully")
      end

      # 4. Проверяем, что ответ содержит правильные данные канала
      it "returns the channel data in the JSON response" do
        post "/api/v1/channels/telegram", params: valid_params, as: :json
        json_response = JSON.parse(response.body)
        expect(json_response['channel']['config']['token']).to eq(valid_telegram_token)
      end
    end

    context "when parameters are invalid" do
      let(:invalid_params) do
        { channel: { config: { token: '' } } }
      end

      it "returns a 422 status and a validation error" do
        post "/api/v1/channels/telegram", params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to eq({ 'token' => [ "must be filled" ] })
      end
    end

    context "when the Telegram API call fails" do
      # Заглушка для неудачной проверки токена
      before do
        stub_request(:get, "#{telegram_api_url}/bot#{valid_telegram_token}/getMe").
          to_return(
            status: 401,
            body: {
              ok: false,
              description: "Unauthorized"
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it "returns a 422 status and a service error message" do
        post "/api/v1/channels/telegram", params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Telegram API returned a non-200 status: 401")
      end
    end
  end
end

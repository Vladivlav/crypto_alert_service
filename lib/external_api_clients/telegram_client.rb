# lib/external_apis/telegram_client.rb

require "faraday"

module ExternalApis
  class TelegramClient
    SEND_MESSAGE_URL = "https://api.telegram.org/bot%s/sendMessage"

    def initialize(bot_token:, http_client: Faraday.default_connection)
      @bot_token        = bot_token
      @http_client      = http_client
      @send_message_url = SEND_MESSAGE_URL % bot_token
    end

    def send_message(chat_id:, text:)
      payload = { chat_id: chat_id, text: text }

      http_client.post(send_message_url, payload.to_json, "Content-Type" => "application/json")
    rescue Faraday::Error, StandardError => e
      false
    end

    private

    attr_reader :bot_token, :http_client, :send_message_url
  end
end

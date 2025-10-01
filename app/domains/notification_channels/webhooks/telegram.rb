# frozen_string_literal: true

require "dry/monads"

module NotificationChannels
  module Webhooks
    class Telegram
      include Dry::Monads[:result]

      TELEGRAM_API_URL = "https://api.telegram.org"

      def call(channel)
        webhook_url = Rails.application.routes.url_helpers.api_v1_telegram_webhook_url(
          webhook_token: channel.webhook_token,
          host: Rails.application.credentials.app_host
        )
        response = Faraday.post("https://api.telegram.org/bot#{channel.config['token']}/setWebhook", url: webhook_url)

        unless response.status == 200
          return Failure("Telegram API returned a non-200 status: #{response.status}")
        end

        body = JSON.parse(response.body)

        unless body["ok"] == true
          return Failure("Telegram API returned an 'ok' status of false")
        end
        Success()
      rescue JSON::ParserError
        Failure("Telegram API returned an invalid JSON response")
      rescue Faraday::Error => e
        Failure("Network error during Telegram API call: #{e.message}")
      end
    end
  end
end

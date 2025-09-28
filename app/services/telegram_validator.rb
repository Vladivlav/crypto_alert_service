# frozen_string_literal: true

require "dry/monads"

class TelegramValidator
  include Dry::Monads[:result]

  TELEGRAM_API_URL = "https://api.telegram.org"

  def call(token)
    response = Faraday.get("#{TELEGRAM_API_URL}/bot#{token}/getMe")

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

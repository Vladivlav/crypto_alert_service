# app/requests/binance/get_cryptopairs.rb

require "dry/monads"
require "net/http"
require "json"

module Requests
  module Binance
    class GetCryptoPairs
      include Dry::Monads[:result]

      BINANCE_API_URL = "https://api.binance.com/api/v3/exchangeInfo".freeze

      def self.call
        new.call
      end

      def call
        uri      = URI(BINANCE_API_URL)
        response = Net::HTTP.get(uri)
        data     = JSON.parse(response)

        symbols = data["symbols"].map { |s| s["symbol"] }

        Success(symbols)
      rescue JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout => e
        Failure("Failed to fetch pairs from Binance API: #{e.message}")
      end
    end
  end
end

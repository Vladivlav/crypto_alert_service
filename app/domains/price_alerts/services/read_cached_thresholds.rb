# app/domains/price_alerts/services/read_cached_thresholds.rb

require "dry/monads"

module PriceAlerts
  module Services
    class ReadCachedThresholds
      include Dry::Monads[:result]

      DEFAULT_EMPTY_JSON_ARRAY = "[]"
      REDIS_THRESHOLD_PREFIX   = "active_thresholds_by_symbol:"

      def initialize(redis_client: Sidekiq.redis { |conn| conn })
        @redis_client = redis_client
      end

      def call(symbol)
        json_data   = redis_client.get(REDIS_THRESHOLD_PREFIX + symbol.upcase)
        json_data ||= DEFAULT_EMPTY_JSON_ARRAY

        threshold_hashes = JSON.parse(json_data, symbolize_names: true)
        threshold_models = threshold_hashes.map { |hash| PriceThreshold.from_cache(hash) }

        Success(threshold_models)
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse cached thresholds for #{symbol}: #{e.message}")
        Failure("Invalid cached data inside Redis")
      end

      private

      attr_reader :redis_client
    end
  end
end

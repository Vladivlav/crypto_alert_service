# app/domains/price_alerts/services/initialize_direction.rb

require "dry/monads"

module PriceAlerts
  module Services
    class InitializeDirection
      include Dry::Monads[:result]

      def initialize(redis_client: Sidekiq.redis { |conn| conn })
        @redis_client = redis_client
      end

      def call(price, key, threshold)
        initial_state = price >= threshold.value ? "ABOVE" : "BELOW"

        redis_client.set(key, initial_state)
        Success(initial_state)
      end

      private

      attr_reader :redis_client
    end
  end
end

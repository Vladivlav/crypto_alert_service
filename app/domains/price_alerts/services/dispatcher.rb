# app/domains/price_alerts/services/dispatcher.rb

require "dry/monads"

module PriceAlerts
  module Services
    class Dispatcher
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(
        redis_client: Sidekiq.redis { |conn| conn },
        cache_price_position: SavePricePositionToRedis.new,
        crossover_check: Guards::CrossoverCheck.new,
        send_alert: Services::EnqueuePriceAlert.new
      )
        @redis_client         = redis_client
        @cache_price_position = cache_price_position
        @crossover_check      = crossover_check
        @send_alert           = send_alert
      end

      def call(threshold, current_price)
        current_state = state_from_redis(threshold)

        return cache_price_position.call(threshold, current_price) if current_state.nil?

        yield crossover_check.call(threshold, current_price, current_state)
        yield cache_price_position.call(threshold, current_price)
        yield send_alert.call(threshold)

        Success(threshold)
      end

      private

      attr_reader :threshold, :current_price, :redis_client, :cache_price_position, :crossover_check, :send_alert

      def state_from_redis(threshold)
        @state_from_redis ||= redis_client.get("threshold_state:#{threshold.id}")
      end
    end
  end
end

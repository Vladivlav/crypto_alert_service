# frozen_string_literal: true

require "dry/monads"

module PriceAlerts
  module Services
    class SavePricePositionToRedis
      include Dry::Monads[:result]

      STATE_ABOVE = "ABOVE"
      STATE_BELOW = "BELOW"

      def initialize(threshold:, current_price:, redis_client: Sidekiq.redis { |conn| conn })
        @current_position = current_price >= threshold.value ? STATE_ABOVE : STATE_BELOW
        @redis_client     = redis_client
        @redis_key        = "threshold_state:#{threshold.id}"
      end

      def call
        result = redis_client.set(redis_key, current_position)
        Success(result)
      rescue Redis::CommandError, Redis::CannotConnectError => e
        Failure("Can not connect to Redis")
      end

      private

      attr_reader :redis_client, :current_position, :redis_key
    end
  end
end

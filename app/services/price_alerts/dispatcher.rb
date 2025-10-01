# app/services/price_alerts/dispatcher.rb

require "dry/monads"

module PriceAlerts
  class Dispatcher
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)

    def initialize(
      redis_client: Sidekiq.redis { |conn| conn },
      initializer_service: PriceAlerts::InitializeDirection.new,
      rising_handler: PriceAlerts::HandleRisingPrice.new,
      falling_handler: PriceAlerts::HandleFallingPrice.new
    )
      @redis_client    = redis_client
      @initializer     = initializer_service
      @rising_handler  = rising_handler
      @falling_handler = falling_handler
    end

    def call(threshold, current_price)
      key           = redis_key(threshold)
      current_state = redis_client.get(key)

      return initializer.call(current_price, key, threshold) if current_state.nil?

      case threshold.operator
      when "up"
        yield rising_handler.call(current_price, key, threshold, current_state)
      when "down"
        yield falling_handler.call(current_price, key, threshold, current_state)
      else
        return Failure(:unknown_threshold_operator)
      end

      Success(true)
    end

    private

    attr_reader :redis_client, :initializer, :rising_handler, :falling_handler

    def redis_key(threshold)
      "threshold_state:#{threshold.id}"
    end
  end
end

# app/services/price_alerts/handle_rising_price.rb

require "dry/monads"

module PriceAlerts
  class HandleRisingPrice
    include Dry::Monads[:result]

    def initialize(
      redis_client: Sidekiq.redis { |conn| conn },
      send_notifications_service: Notifications::SendNotificationService.new
    )
      @redis_client = redis_client
      @send_notifications_service = send_notifications_service
    end

    def call(price, key, threshold, state)
      if price >= threshold.value && state == "BELOW"
        send_notifications_service.call(threshold)
        redis_client.set(key, "ABOVE")
      elsif price < threshold.value && state == "ABOVE"
        redis_client.set(key, "BELOW")
      end
      Success()
    end

    private

    attr_reader :redis_client, :send_notifications_service
  end
end

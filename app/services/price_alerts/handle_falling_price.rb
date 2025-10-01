require "dry/monads"

module PriceAlerts
  class HandleFallingPrice
    include Dry::Monads[:result]

    def initialize(
      redis_client: Sidekiq.redis { |conn| conn },
      send_notifications_service: Notifications::SendNotificationService.new
    )
      @redis_client = redis_client
      @send_notifications_service = send_notifications_service
    end

    def call(price, key, threshold, state)
      if price <= threshold.value && state == "ABOVE"
        send_notifications_service.call(threshold)
        redis_client.set(key, "BELOW")
      elsif price > threshold.value && state == "BELOW"
        redis_client.set(key, "ABOVE")
      end

      Success()
    rescue => e
      Failure("HandleFallingPrice error: #{e.message}")
    end

    private

    attr_reader :redis_client, :send_notifications_service
  end
end

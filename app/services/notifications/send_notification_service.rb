# app/services/notifications/send_notification_service.rb

require "dry/monads"

module Notifications
  class SendNotificationService
    include Dry::Monads[:result]

    def initialize(
      notification_worker: NotificationWorker,
      notification_channel_model: NotificationChannel
    )
      @notification_worker = notification_worker
      @notification_channel_model = notification_channel_model
    end

    def call(threshold)
      active_channels.each do |channel|
        notification_worker.perform_async(
          channel.id,
          threshold.id,
          threshold.symbol,
          threshold.value.to_s
        )
      end

      Success(active_channels)
    rescue => e
      Failure("Enqueue message error: #{e.message}")
    end

    private

    attr_reader :notification_worker, :notification_channel_model

    def active_channels
      @active_channels ||= notification_channel_model.active
    end
  end
end

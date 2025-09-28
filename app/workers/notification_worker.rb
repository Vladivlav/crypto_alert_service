require "sidekiq"

class NotificationWorker
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  SENDER_MAP = {
    "logs" => NotificationChannels::Services::Logs::SaveAlert,
    "telegram" => NotificationChannels::Services::Telegram::SendMessage
  }.freeze

  def initialize(
    channel_model: NotificationChannel,
    threshold_model: PriceThreshold,
    formatter: NotificationChannels::Translators::PriceAlertMessage.new
  )
    @channel_model   = channel_model
    @threshold_model = threshold_model
    @formatter       = formatter
  end

  def perform(channel_id, threshold_id)
    channel   = channel_model.find(channel_id)
    threshold = threshold_model.find(threshold_id)
    message   = formatter.call(threshold)

    sender_class = SENDER_MAP[channel.channel_type]

    if sender_class
      result = sender_class.new.call(channel: channel, message: message)

      if result.failure?
        Rails.logger.error "Notification dispatch failed for channel #{channel_id} via #{channel.channel_type}: #{result.failure}"
        raise "Notification Sender Failed"
      end

      Rails.logger.info "Notification successfully dispatched for #{threshold.symbol} via #{channel.channel_type}"
    else
      Rails.logger.warn "NotificationWorker: Unknown channel type '#{channel.channel_type}' for channel ID #{channel_id}. Skipping."
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "NotificationWorker: Record not found (deleted alert/channel): #{e.message}"
  rescue StandardError => e
    Rails.logger.error "NotificationWorker critical error: #{e.message}"
    raise
  end

  private

  attr_reader :channel_model, :threshold_model, :formatter
end

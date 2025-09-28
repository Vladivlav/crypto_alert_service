# app/services/add_telegram_channel_service.rb

require "dry/monads"

class AddTelegramChannel
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  def initialize(
    validator: TelegramValidator.new,
    webhook_service: TelegramWebhook.new,
    channel_model: NotificationChannel
  )
    @validator       = validator
    @webhook_service = webhook_service
    @channel_model   = channel_model
  end

  def self.call(token:)
    new.call(token: token)
  end

  def call(token:)
    validate_result = yield validator.call(token)
    channel = channel_model.create(
      channel_type: "telegram",
      config: { token: token },
      is_active: false
    )
    return Failure("Failed to create channel record.") unless channel.persisted?
    yield webhook_service.call(channel)

    Success(channel)
  end

  private

  attr_reader :validator, :webhook_service, :channel_model
end

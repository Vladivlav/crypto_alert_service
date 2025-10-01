# app/services/telegram_message_processor.rb

require "dry/monads"

class TelegramMessageProcessor
  include Dry::Monads[:result]

  def initialize(
    activator_service: NotificationChannels::Services::Telegram::ActivateChannel,
    deactivator_service: NotificationChannels::Services::Disable.new
  )
    @activator = activator_service
    @deactivator = deactivator_service
  end

  def self.call(channel:, message:)
    new.call(channel: channel, message: message)
  end

  def call(channel:, message:)
    return Failure("No Chat ID found.") if message.nil? || message.dig("chat", "id").nil?

    case message.dig("text")
    when "/start"
      @activator.call(channel: channel, chat_id: message.dig("chat", "id").to_s)
    when "/stop"
      @deactivator.call(channel: channel)
    else
      Success()
    end
  end
end

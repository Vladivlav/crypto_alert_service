require "dry/monads"

module Builders
  class NotificationSender
    include Dry::Monads[:result]

    TYPES = ChannelCreation::TYPES

    def call(channel_type)
      unless TYPES.include?(channel_type.to_s)
        return Failure("Unsupported notification channel type: #{channel_type}")
      end

      service = case channel_type.to_s
      when "email"
        Notifications::Email::SendMessage
      when "telegram"
        Notifications::Telegram::SendMessage
      when "sms"
        Notifications::Sms::SendMessage
      else
        return Failure("The channel is not implemented: #{channel_type}")
      end

      Success(service)
    end
  end
end

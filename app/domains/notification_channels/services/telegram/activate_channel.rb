# app/domains/notification_channels/services/telegram/activate_channel.rb

require "dry/monads"

module NotificationChannels
  module Services
    module Telegram
      class ActivateChannel
        include Dry::Monads[:result]

        def self.call(channel:, chat_id:)
          new.call(channel: channel, chat_id: chat_id)
        end

        def call(channel:, chat_id:)
          channel.is_active = true
          channel.chat_id   = chat_id.to_s

          if channel.save
            Success(channel)
          else
            Failure("Failed to activate channel ID #{channel.id}: #{channel.errors.full_messages.join(', ')}")
          end
        end
      end
    end
  end
end

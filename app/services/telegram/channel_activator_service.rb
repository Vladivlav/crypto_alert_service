# app/services/telegram/channel_activator_service.rb
require "dry/monads"

module Telegram
  class ChannelActivatorService
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

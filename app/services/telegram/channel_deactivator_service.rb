# app/services/telegram/channel_deactivator_service.rb
require "dry/monads"

module Telegram
  class ChannelDeactivatorService
    include Dry::Monads[:result]

    def self.call(channel:)
      new.call(channel: channel)
    end

    def call(channel:)
      channel.is_active = false

      if channel.save
        Success(channel)
      else
        Failure("Failed to deactivate channel ID #{channel.id}: #{channel.errors.full_messages.join(', ')}")
      end
    end
  end
end

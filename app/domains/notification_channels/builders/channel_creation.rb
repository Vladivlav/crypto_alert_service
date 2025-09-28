# app/builders/channel_creation.rb

module NotificationChannels
  module Builders
    class ChannelCreation
      TYPES = %w[telegram sms].freeze

      def self.for(channel_type)
        case channel_type
        when "telegram"
          {
            contract: Contracts::Telegram,
            scenario: Scenarios::CreateTelegramChannel
          }
        when "text_logs"
          {
            contract: Contracts::Log,
            scenario: Scenarios::CreateLogsChannel
          }
        else
          raise Errors::InvalidChannelType, "Unsupported channel type: #{channel_type}"
        end
      end
    end
  end
end

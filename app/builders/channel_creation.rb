# app/builders/channel_creation.rb

class ChannelCreation
  TYPES = %w[telegram sms].freeze

  def self.for(channel_type)
    case channel_type
    when "telegram"
      {
        contract: NotificationChannels::Contracts::Telegram,
        scenario: NotificationChannels::Scenarios::CreateTelegramChannel
      }
    else
      raise Errors::InvalidChannelType, "Unsupported channel type: #{channel_type}"
    end
  end
end

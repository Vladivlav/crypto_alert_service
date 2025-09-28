# app/builders/channel_creation.rb

class ChannelCreation
  TYPES = %w[telegram].freeze

  def self.for(channel_type)
    case channel_type
    when "telegram"
      {
        contract: TelegramToken,
        service: AddTelegramChannel
      }
    else
      raise Errors::InvalidChannelType, "Unsupported channel type: #{channel_type}"
    end
  end
end

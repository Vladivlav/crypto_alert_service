# app/domains/notification_channels/services/disable.rb

require "dry/monads"

module NotificationChannels
  module Services
    class Disable
      include Dry::Monads[:result]

      def call(channel)
        channel.is_active = false

        if channel.save
          Success(channel)
        else
          error_message = channel.errors.full_messages.join(", ")
          Failure("Failed to deactivate channel ID #{channel.id}: #{error_message}")
        end
      end
    end
  end
end

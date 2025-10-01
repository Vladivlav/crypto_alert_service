# app/domains/notification_channels/services/disable.rb

require "dry/monads"

module NotificationChannels
  module Services
    class Disable
      include Dry::Monads[:result]

      def call(channel)
        channel.is_active = false
        channel.save!

        Success(channel)
      rescue => e
        Failure("Can not disable channel, reason: #{e}")
      end
    end
  end
end

# app/domains/notification_channels/services/logs/check_file_exist.rb

require "dry/monads"

module NotificationChannels
  module Services
    module Logs
      class CheckFileExist
        include Dry::Monads[:result]

        CHANNEL_LOGS_DIR = Rails.root.join("log", "channels")

        def call(file_name)
          file_path = CHANNEL_LOGS_DIR.join(file_name)

          if File.exist?(file_path)
            Failure("Choose another name to save logs")
          else
            Success(file_path)
          end
        end
      end
    end
  end
end

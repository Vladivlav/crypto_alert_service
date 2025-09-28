# app/domains/notification_channels/services/logs/save_alert.rb

require "dry/monads"

module NotificationChannels
  module Services
    module Logs
      class SaveAlert
        include Dry::Monads[:result]

        CHANNEL_LOGS_DIR = Rails.root.join("log", "channels")

        def call(channel:, message_text:)
          return Failure(:missing_logs_filename) if channel.logs_filename.nil?

          file_path = CHANNEL_LOGS_DIR.join(channel.logs_filename)

          timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
          log_entry = "[#{timestamp}] #{message_text}\n"

          File.open(file_path, "a") do |f|
            f.write(log_entry)
          end

          Success(file_path.to_s)
        rescue Errno::ENOENT, Errno::EACCES, IOError => e
          Failure("file_io_error_#{e.class.name.underscore}")
        rescue StandardError => e
          Failure("critical_error_#{e.class.name.underscore}")
        end
      end
    end
  end
end

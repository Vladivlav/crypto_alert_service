# app/domains/notification_channels/scenarios/create_logs_channel.rb2

require "fileutils"
require "dry/monads"

module NotificationChannels
  module Scenarios
    class CreateLogsChannel
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(
        filename_guard: Services::Logs::CheckFileExist.new,
        channel_model: NotificationChannel
      )
        @filename_guard = filename_guard
        @channel_model  = channel_model
      end

      def self.call(file_name:)
        new.call(file_name: file_name)
      end

      def call(file_name:)
        full_logs_path = yield filename_guard.call(file_name)

        File.open(full_logs_path.to_s, "w").close
        channel   = channel_model.create(
          channel_type: "text_logs",
          config: { file_name: file_name },
          is_active: true
        )

        if channel.persisted?
          Success(channel)
        else
          Failure("Failed to create channel record.")
        end
      end

      private

      attr_reader :filename_guard, :channel_model
    end
  end
end

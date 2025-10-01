# app/domains/notification_channels/services/telegram/send_message.rb

require "dry/monads"
require "json"

module NotificationChannels
  module Services
    module Telegram
      class SendMessage
        include Dry::Monads[:result]

        def initialize(
          client_class: ExternalApis::TelegramClient,
          logger: Rails.logger,
          channel_disabler: Channels::Disable.new
        )
          @client_class     = client_class
          @logger           = logger
          @channel_disabler = channel_disabler
        end

        def call(channel:, message_text:)
          return Failure(:missing_credentials) if channel.bot_token.nil? || channel.chat_id.nil?

          client   = client_class.new(bot_token: channel.bot_token, chat_id: channel.chat_id)
          response = client.send_message(text: message_text)

          if response.status == 200
            response_body = JSON.parse(response.body)

            if response_body["ok"] == true
              Success(:sent_successfully)
            else
              error_desc = response_body["description"] || "Неизвестная ошибка Telegram API."
              Failure("telegram_api_error_#{error_desc.to_s.gsub(/\s+/, '_')}".to_sym)
            end
          else
            Failure("http_error_#{response.status}".to_sym)
          end
        rescue JSON::ParserError
          Failure(:json_parse_error)
        rescue StandardError => e
          Failure("critical_error_#{e.class.name.underscore}".to_sym)
        ensure
          channel_disabler.call(channel)
        end

        private

        attr_reader :client_class, :logger, :channel_disabler
      end
    end
  end
end

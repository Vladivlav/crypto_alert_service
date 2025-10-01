# app/domains/notification_channel/contracts/telegram.rb

require "dry/validation"

module NotificationChannels
  module Contracts
    class Telegram < Dry::Validation::Contract
      params do
        required(:token).filled(:string)
      end

      rule(:token) do
        key.failure("invalid format") unless value =~ /\A\d+:[A-Za-z0-9_-]+\z/
      end
    end
  end
end

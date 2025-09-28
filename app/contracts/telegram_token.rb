# app/contracts/telegram_token_contract.rb

require "dry/validation"

class TelegramToken < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
  end

  rule(:token) do
    key.failure("invalid format") unless value =~ /\A\d+:[A-Za-z0-9_-]+\z/
  end
end

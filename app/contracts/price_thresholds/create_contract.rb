# app/contracts/price_thresholds/create_contract.rb
require "dry-validation"
require "bigdecimal"

module PriceThresholds
  class CreateContract < Dry::Validation::Contract
    params do
      required(:symbol).filled(:string)
      required(:value).filled(:string)
      required(:operator).filled(:string)
    end

    rule(:symbol) do
      key.failure("должен содержать только заглавные буквы и цифры") unless value.match?(/\A[A-Z0-9]+\z/)
    end

    rule(:operator) do
      key.failure("должен быть одним из: up (рост) или down (падение)") unless %w[up down].include?(value)
    end

    rule(:value) do
      key.failure("должно быть валидным числом") unless value.match?(/\A\d+(\.\d+)?\z/)
      key.failure("должно быть положительным числом") if value.to_f <= 0
    end
  end
end

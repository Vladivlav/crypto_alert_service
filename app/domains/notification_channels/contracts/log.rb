require "dry/validation"

module NotificationChannels
  module Contracts
    class Log < Dry::Validation::Contract
      params do
        required(:file_name).filled(:string)
      end

      rule(:file_name) do
        allowed_chars_regex = /\A[\w-]+\z/i

        unless value =~ allowed_chars_regex
          key.failure("Must contain of digits, chars and underscores")
        end
      end
    end
  end
end

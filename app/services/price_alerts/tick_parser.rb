# app/services/price_alerts/tick_parser.rb

require "dry/monads"

module PriceAlerts
  class TickParser
    include Dry::Monads[:result]

    def call(data)
      message      = JSON.parse(data, symbolize_names: true)
      data_payload = message[:data]

      raise Errors::EmptyTickBody.new if invalid_payload?(data_payload)

      symbol = data_payload[:s]
      price  = BigDecimal(data_payload[:p])

      Success([ symbol, price ])
    rescue JSON::ParserError, Errors::EmptyTickBody
      Failure("Can not parse tick data")
    end

    private

    def invalid_payload?(payload)
      payload.nil? || payload[:s].nil? || payload[:p].nil?
    end
  end
end

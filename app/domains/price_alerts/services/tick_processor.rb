# app/domains/price_alerts/services/tick_processor.rb

require "dry/monads"

module PriceAlerts
  module Services
    class TickProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(
        raw_data_parser: PriceAlerts::TickParser.new,
        read_cached_thresholds: PriceAlerts::ReadCachedThresholds.new,
        dispatcher_service: PriceAlerts::Dispatcher.new
      )
        @raw_data_parser        = raw_data_parser
        @read_cached_thresholds = read_cached_thresholds
        @dispatcher             = dispatcher_service
      end

      def call(raw_data)
        symbol, price     = yield raw_data_parser.call(raw_data)
        active_thresholds = yield read_cached_thresholds.call(symbol)

        active_thresholds.each do |threshold|
          yield dispatcher.call(threshold, price)
        end

        Success(active_thresholds)
      end

      private

      attr_reader :dispatcher, :raw_data_parser, :read_cached_thresholds
    end
  end
end

# app/domains/price_thresholds/scenarios/create.rb
require "dry/monads"
require "bigdecimal"

module PriceThresholds
  module Scenarios
    class Create
      include Dry::Monads[:result]

      MAX_ACTIVE_THRESHOLDS = 1000
      MAX_LIMIT_ERROR_MSG = "Превышен лимит активных заявок."
      SYMBOL_NOT_FOUND_ERROR_MSG = "Символ не существует в списке отслеживаемых криптопар."

      def initialize(
        model_klass: PriceThreshold,
        pair_model_klass: CryptoPair,
        redis_synchronizer: PriceThresholds::RedisSynchronizer
      )
        @model_klass        = model_klass
        @pair_model_klass   = pair_model_klass
        @redis_synchronizer = redis_synchronizer
      end

      def call(params)
        return Failure(MAX_LIMIT_ERROR_MSG)        unless model_klass.user_has_capacity?
        return Failure(SYMBOL_NOT_FOUND_ERROR_MSG) unless pair_model_klass.exists?(symbol: params[:symbol])

        final_data = prepare_final_data(params)
        threshold  = model_klass.create!(final_data)

        redis_synchronizer.call(threshold)
        Success(threshold)
      end

      private

      attr_reader :model_klass, :pair_model_klass, :redis_synchronizer

      def prepare_final_data(safe_data)
        {
          symbol: safe_data[:symbol],
          value: BigDecimal(safe_data[:value]),
          operator: safe_data[:operator],
          is_active: true
        }
      end
    end
  end
end

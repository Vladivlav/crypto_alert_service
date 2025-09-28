# app/domains/binance/services/pair_sync_service.rb

require "dry/monads"

module Binance
  module Services
    class SyncPairs
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(
        request_service: Binance::Requests::GetCryptoPairs,
        pair_model: CryptoPair
      )
        @request_service = request_service
        @pair_model      = pair_model
      end

      def call
        api_pairs_list   = yield request_service.call
        db_pairs         = pair_model.pluck(:symbol).to_a
        new_pairs        = api_pairs_list - db_pairs

        if new_pairs.present?
          values_to_insert = new_pairs.map { |symbol| { symbol: symbol } }
          pair_model.insert_all(values_to_insert, unique_by: :symbol)
        end
        Success(new_pairs)
      end

      private

      attr_reader :request_service, :pair_model
    end
  end
end

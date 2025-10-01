require 'rails_helper'
require 'bigdecimal'
require 'dry/monads'

module PriceAlerts
  RSpec.describe Services::TickProcessor do
    include Dry::Monads[:result]

    let(:raw_data) { '{"raw_data":"btcusdt@trade"}' }
    let(:symbol)   { 'BTCUSDT' }
    let(:price)    { BigDecimal('70000.00') }

    let(:threshold_1)       { build :price_threshold, id: 1, value: BigDecimal('71000') }
    let(:threshold_2)       { build :price_threshold, id: 2, value: BigDecimal('69000') }
    let(:active_thresholds) { [ threshold_1, threshold_2 ] }

    let(:success_dependencies) do
      {
        raw_data_parser: parser_success,
        read_cached_thresholds: read_cache_success,
        dispatcher_service: dispatcher_success
      }
    end

    let(:parser_failure)     { ->(raw_data) { Failure(:invalid_json_format) } }
    let(:read_cache_failure) { ->(symbol) { Failure(:redis_unavailable) } }
    let(:dispatcher_failure) { ->(threshold, price) { Failure(:notification_service_down) } }

    let(:parser_success)     { ->(raw_data) { Success([ symbol, price ]) } }
    let(:read_cache_success) { ->(symbol) { Success(active_thresholds) } }
    let(:dispatcher_success) { ->(threshold, price) { Success() } }

    let(:evaluator) { described_class.new(**dependencies) }

    RSpec.shared_examples 'aborts flow with failure' do |failure_block|
      it 'immediately aborts the flow and returns the expected Failure object' do
        result = evaluator.call(raw_data)
        expected_failure = instance_exec(&failure_block)
        expect(result).to eq(expected_failure)
        expect(result).to be_failure
      end
    end

    RSpec.shared_examples 'processes all thresholds successfully' do
      it 'processes all thresholds and returns Success with active thresholds' do
        result = evaluator.call(raw_data)

        expect(result).to be_success
        expect(result.value!).to eq(active_thresholds)
      end
    end

    context '1. When the TickParser returns Failure' do
      let(:dependencies) { success_dependencies.merge(raw_data_parser: parser_failure) }

      it_behaves_like 'aborts flow with failure', -> { parser_failure.call(raw_data) }
    end

    context '2. When ReadCachedThresholds returns Failure' do
      let(:dependencies) { success_dependencies.merge(read_cached_thresholds: read_cache_failure) }

      it_behaves_like 'aborts flow with failure', -> { read_cache_failure.call(symbol) }
    end

    context '3. When a Dispatcher call returns Failure' do
      let(:dependencies) { success_dependencies.merge(dispatcher_service: dispatcher_failure) }

      it_behaves_like 'aborts flow with failure', -> { dispatcher_failure.call(threshold_1, price) }
    end

    context '4. When all dependencies return Success' do
      let(:dependencies) { success_dependencies }

      it_behaves_like 'processes all thresholds successfully'
    end
  end
end

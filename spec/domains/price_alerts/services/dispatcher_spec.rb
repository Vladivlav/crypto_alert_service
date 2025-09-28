require 'rails_helper'
require 'dry/monads'

module PriceAlerts
  RSpec.describe Services::Dispatcher do
    include Dry::Monads[:result]

    let(:current_price) { BigDecimal('70000.00') }
    let(:threshold)     { build_stubbed(:price_threshold, id: 123, operator: 'up', value: BigDecimal('69500.00')) }
    let(:key)           { "threshold_state:123" }
    let(:redis_client)  { instance_double(Redis) }

    # SUCCESS MOCKS
    let(:crossover_success)            { ->(threshold, current_price, previous_state) { Success(:crossover_detected) } }
    let(:cache_price_position_success) { ->(threshold, price) { Success('ABOVE') } }
    let(:send_alert_success)           { ->(threshold) { Success() } }

    # FAILURE MOCKS
    let(:crossover_no_change)          { ->(threshold, current_price, previous_state) { Failure(:no_crossover) } }
    let(:cache_price_position_failure) { ->(threshold, price) { Failure(:redis_write_error) } }
    let(:send_alert_failure)           { ->(threshold) { Failure(:notification_service_down) } }


    let(:success_dependencies) do
      {
        redis_client: redis_client,
        crossover_check: crossover_success,
        cache_price_position: cache_price_position_success,
        send_alert: send_alert_success
      }
    end

    context 'when previous state is not found in Redis (First Run)' do
      let(:service) { described_class.new(**success_dependencies) }

      before do
        allow(redis_client).to receive(:get).with(key).and_return(nil)

        expect(success_dependencies[:cache_price_position]).to receive(:call).with(threshold, current_price).and_call_original
        expect(success_dependencies[:crossover_check]).not_to receive(:call)
        expect(success_dependencies[:send_alert]).not_to receive(:call)
      end

      it 'fetches nil from redis, skips checks, calls SavePricePositionToRedis, and returns its result' do
        result = service.call(threshold, current_price)

        # Проверка конечного результата
        # Ожидаем Success с новым состоянием, которое вернул мок cache_price_position
        expect(result).to eq(Success('ABOVE'))
      end
    end

    RSpec.shared_examples 'aborts flow with failure' do |failure_block|
      it 'immediately aborts the flow and returns the expected Failure object' do
        result = dispatcher.call(threshold, current_price)
        expected_failure = instance_exec(&failure_block)
        expect(result).to eq(expected_failure)
        expect(result).to be_failure
      end
    end

    RSpec.shared_examples 'processes all thresholds successfully' do
      it 'processes all thresholds and returns Success with active thresholds' do
        result = dispatcher.call(threshold, current_price)

        expect(result).to be_success
        expect(result.value!).to eq(threshold)
      end
    end

    before do
      allow(redis_client).to receive(:get).with(key).and_return("ABOVE")
    end

    let(:dispatcher) { described_class.new(**dependencies) }

    context '1. When the TickParser returns Failure' do
      let(:dependencies) { success_dependencies.merge(crossover_check: crossover_no_change) }

      it_behaves_like 'aborts flow with failure', -> { crossover_no_change.call(threshold, current_price, "BELOW") }
    end

    context '2. When ReadCachedThresholds returns Failure' do
      let(:dependencies) { success_dependencies.merge(cache_price_position: cache_price_position_failure) }

      it_behaves_like 'aborts flow with failure', -> { cache_price_position_failure.call(threshold, current_price) }
    end

    context '3. When a Dispatcher call returns Failure' do
      let(:dependencies) { success_dependencies.merge(send_alert: send_alert_failure) }

      it_behaves_like 'aborts flow with failure', -> { send_alert_failure.call(threshold) }
    end

    context '4. When all dependencies return Success' do
      let(:dependencies) { success_dependencies }

      it_behaves_like 'processes all thresholds successfully'
    end
  end
end

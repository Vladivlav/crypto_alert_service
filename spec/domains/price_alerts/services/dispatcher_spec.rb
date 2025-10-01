require 'rails_helper'
require 'dry/monads'

module PriceAlerts
  RSpec.describe Services::Dispatcher do
    include Dry::Monads[:result]

    let(:redis_client)  { instance_double(Redis) }
    let(:initializer)   { instance_double(Services::InitializeDirection) }
    let(:rising_handler) { instance_double(Services::HandleRisingPrice) }
    let(:falling_handler) { instance_double(Services::HandleFallingPrice) }

    let(:dispatcher) do
      described_class.new(
        redis_client: redis_client,
        initializer_service: initializer,
        rising_handler: rising_handler,
        falling_handler: falling_handler
      )
    end

    # --- 2. Общие Входные Данные ---
    let(:current_price) { BigDecimal('70000.00') }
    let(:threshold_value) { BigDecimal('69500.00') }

    let(:threshold) do
      build_stubbed(:price_threshold, symbol: "BTCUSDT", id: 123, operator: 'up', value: threshold_value)
    end

    let(:key) { "threshold_state:123" }

    before do
      allow(initializer).to receive(:call).and_return(Success('ABOVE'))
      allow(rising_handler).to receive(:call).and_return(Success())
      allow(falling_handler).to receive(:call).and_return(Success())
    end

    context 'when Redis state is NIL (Initialization Scenario)' do
      before do
        allow(redis_client).to receive(:get).with(key).and_return(nil)
      end

      it 'calls the InitializeDirection service and returns its result' do
        expect(initializer).to receive(:call).once.with(current_price, key, threshold)
        expect(rising_handler).not_to receive(:call)
        expect(falling_handler).not_to receive(:call)

        result = dispatcher.call(threshold, current_price)
        expect(result).to be_success
        expect(result.value!).to eq('ABOVE')
      end
    end

    context 'when Redis state is set and operator is "up" (Rising Price Scenario)' do
      before do
        allow(redis_client).to receive(:get).with(key).and_return('BELOW')
        threshold.operator = 'up'
      end

      it 'calls the HandleRisingPrice handler' do
        expect(initializer).not_to receive(:call)
        expect(rising_handler).to receive(:call).once.with(current_price, key, threshold, 'BELOW')
        expect(falling_handler).not_to receive(:call)

        result = dispatcher.call(threshold, current_price)
        expect(result).to be_success
      end
    end

    context 'when Redis state is set and operator is "down" (Falling Price Scenario)' do
      before do
        # Имитируем, что Redis вернул предыдущее состояние
        allow(redis_client).to receive(:get).with(key).and_return('ABOVE')
        threshold.operator = 'down'
      end

      it 'calls the HandleFallingPrice handler' do
        # Проверяем, что вызывается только хендлер падения
        expect(initializer).not_to receive(:call)
        expect(rising_handler).not_to receive(:call)
        expect(falling_handler).to receive(:call).once.with(current_price, key, threshold, 'ABOVE')

        result = dispatcher.call(threshold, current_price)
        expect(result).to be_success
      end
    end

    context 'when alert operator is unknown' do
      before do
        allow(redis_client).to receive(:get).with(key).and_return('ABOVE')
        threshold.operator = 'unknown_op'
      end

      it 'returns Failure(:unknown_alert_operator)' do
        expect(initializer).not_to receive(:call)
        expect(rising_handler).not_to receive(:call)
        expect(falling_handler).not_to receive(:call)

        result = dispatcher.call(threshold, current_price)
        expect(result).to be_failure
        expect(result.failure).to eq(:unknown_threshold_operator)
      end
    end
  end
end

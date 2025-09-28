require 'rails_helper'
require 'bigdecimal'

module PriceAlerts
  RSpec.describe Services::TickParser do
    let(:parser) { described_class.new }

    context 'when a valid price tick is received' do
      let(:raw_data) do
        '{"stream":"btcusdt@trade","data":{"e":"trade","E":1678886400000,"s":"BTCUSDT","p":"69420.69","q":"0.001"}}'
      end

      it 'returns Success with the symbol and BigDecimal price' do
        result = parser.call(raw_data)

        expect(result).to be_success

        symbol, price = result.value!

        expect(symbol).to eq('BTCUSDT')

        expected_price = BigDecimal("69420.69")
        expect(price).to be_a(BigDecimal)
        expect(price).to eq(expected_price)
      end
    end

    # --- 2. Сценарий Некорректного JSON ---
    context 'when an invalid JSON string is received' do
      let(:raw_data) { 'This is not a JSON string' }

      it 'returns Failure and does not raise JSON::ParserError' do
        result = parser.call(raw_data)

        # Проверяем, что результат Failure
        expect(result).to be_failure
        # Проверяем, что Failure содержит ожидаемое значение (nil, nil)
        expect(result.failure).to eq("Can not parse tick data")
      end
    end

    context 'when a valid JSON is received but critical fields are missing' do
      # Отсутствует ключ "p" (цена)
      let(:missing_price_data) do
        '{"stream":"btcusdt@trade","data":{"e":"trade","E":1678886400000,"s":"BTCUSDT","q":"0.001"}}'
      end

      # Отсутствует ключ "s" (символ)
      let(:missing_symbol_data) do
        '{"stream":"btcusdt@trade","data":{"e":"trade","E":1678886400000,"p":"69420.69","q":"0.001"}}'
      end

      it 'returns Failure when the price is missing' do
        result = parser.call(missing_price_data)
        expect(result).to be_failure
        expect(result.failure).to eq("Can not parse tick data")
      end

      it 'returns Failure when the symbol is missing' do
        result = parser.call(missing_symbol_data)
        expect(result).to be_failure
        expect(result.failure).to eq("Can not parse tick data")
      end
    end
  end
end

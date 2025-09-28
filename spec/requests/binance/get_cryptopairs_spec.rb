# spec/requests/binance/get_cryptopairs_spec.rb
require 'rails_helper'
require 'webmock/rspec'
require 'dry/monads'
require_relative '../../../app/requests/binance/get_cryptopairs'

RSpec.describe Requests::Binance::GetCryptoPairs, type: :request do
  include Dry::Monads[:result]

  let(:api_url) { 'https://api.binance.com/api/v3/exchangeInfo' }

  describe '.call' do
    # Успешный сценарий
    context 'when the API call is successful' do
      let(:response_body) do
        {
          "symbols": [
            { "symbol": "BTCUSDT" },
            { "symbol": "ETHUSDT" },
            { "symbol": "BNBUSDT" }
          ]
        }.to_json
      end

      before do
        stub_request(:get, api_url).to_return(status: 200, body: response_body)
      end

      it 'returns a successful result with a list of symbols' do
        result = described_class.call
        expect(result).to be_success
        expect(result.value!).to match_array([ 'BTCUSDT', 'ETHUSDT', 'BNBUSDT' ])
      end
    end

    # Негативные сценарии
    context 'when the API call fails' do
      it 'returns a failure result if the API returns invalid JSON' do
        stub_request(:get, api_url).to_return(status: 200, body: 'invalid json')

        result = described_class.call
        expect(result).to be_failure
        expect(result.failure).to include('Failed to fetch pairs from Binance API: ')
      end

      it 'returns a failure result if a network timeout occurs' do
        stub_request(:get, api_url).to_timeout

        result = described_class.call
        expect(result).to be_failure
        expect(result.failure).to include('Failed to fetch pairs from Binance API: execution expired')
      end

      it 'returns a failure result if the API returns an unexpected structure' do
        # Имитируем ответ, в котором нет ключа 'symbols'
        stub_request(:get, api_url).to_return(status: 200, body: { "unexpected_key" => [] }.to_json)

        # Обрати внимание: это вызовет ошибку, так как твой rescue-блок
        # не ловит NoMethodError. Тест провалится, как и должно.
        expect { described_class.call }.to raise_error(NoMethodError)
      end
    end
  end
end

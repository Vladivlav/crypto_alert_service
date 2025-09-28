# spec/services/binance/pair_sync_service_spec.rb
require 'rails_helper'
require 'dry/monads'
require_relative '../../../app/requests/binance/get_cryptopairs'

RSpec.describe Binance::PairSyncService, type: :service do
  include Dry::Monads[:result]

  let(:request_service) { instance_double(Requests::Binance::GetCryptoPairs) }
  let(:pair_model)      { class_double(CryptoPair) }

  subject(:service) { described_class.new(request_service: request_service, pair_model: pair_model) }

  context 'when the request service returns a failure' do
    it 'returns a failure result and does not attempt to save to the database' do
      allow(request_service).to receive(:call).and_return(Failure('API error'))
      expect(pair_model).not_to receive(:insert_all)

      result = service.call

      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to eq('API error')
    end
  end

  context 'when the request service returns a success with pairs' do
    let(:api_pairs) { [ 'BTCUSDT', 'ETHUSDT', 'BNBUSDT' ] }
    let(:all_pairs_to_insert) { [ { symbol: 'BTCUSDT' }, { symbol: 'ETHUSDT' }, { symbol: 'BNBUSDT' } ] }

    before do
      # Мокируем успешный вызов GetCryptopairs
      allow(request_service).to receive(:call).and_return(Success(api_pairs))
      # Мокируем insert_all, чтобы он ничего не делал в тестах
      allow(pair_model).to receive(:insert_all)
    end

    # Кейс 2.1: Нечего обновлять
    context 'when the database already contains all pairs from the API' do
      before do
        allow(pair_model).to receive(:pluck).with(:symbol).and_return(api_pairs)
      end

      it 'returns a success result and does not insert any new records' do
        expect(pair_model).not_to receive(:insert_all)
        result = service.call
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    # Кейс 2.2: Есть что добавить
    context 'when the database contains some but not all pairs from the API' do
      let(:existing_pairs) { [ 'BTCUSDT' ] }
      let(:new_pairs)      { [ 'ETHUSDT', 'BNBUSDT' ] }
      let(:new_pairs_to_insert) { [ { symbol: 'ETHUSDT' }, { symbol: 'BNBUSDT' } ] }

      before do
        allow(pair_model).to receive(:pluck).with(:symbol).and_return(existing_pairs)
      end

      it 'inserts only the new records and returns them in a success result' do
        # Ожидаем, что insert_all будет вызван только с новыми парами
        expect(pair_model).to receive(:insert_all).with(
          new_pairs_to_insert,
          unique_by: :symbol
        )
        result = service.call
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(new_pairs)
      end
    end

    # Кейс 2.3: Таблица пустая
    context 'when the database is empty' do
      before do
        allow(pair_model).to receive(:pluck).with(:symbol).and_return([])
      end

      it 'inserts all pairs received from the API and returns them in a success result' do
        # Ожидаем, что insert_all будет вызван со всеми парами
        expect(pair_model).to receive(:insert_all).with(
          all_pairs_to_insert,
          unique_by: :symbol
        )
        result = service.call
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(api_pairs)
      end
    end
  end
end

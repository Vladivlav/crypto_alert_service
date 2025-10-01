require 'rails_helper'
require_relative '../../../app/services/price_alerts/symbol_manager'

RSpec.describe PriceAlerts::SymbolManager, type: :service do
  let(:redis_client) { Redis.new(db: 15) }

  before(:each) do
    redis_client.flushdb
  end

  let!(:btc_threshold)      { create(:price_threshold, symbol: 'BTCUSDT', is_active: true) }
  let!(:eth_threshold)      { create(:price_threshold, symbol: 'ETHUSDT', is_active: true) }
  let!(:inactive_threshold) { create(:price_threshold, symbol: 'DOGEUSDT', is_active: false) }

  let(:manager)              { described_class.new(redis_client: redis_client) }
  let(:mock_threshold_scope) { class_double('PriceThreshold').as_stubbed_const }
  let(:expected_symbols)     { [ 'BTCUSDT', 'ETHUSDT' ] }


  describe '#active_symbols' do
    context 'when Redis cache is empty (initial run)' do
      it 'fetches symbols from DB, caches them, and returns the list' do
        symbols = manager.active_symbols
        cached_symbols = redis_client.smembers(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY)

        expect(mock_threshold_scope).to receive(:where).and_call_original
        expect(symbols).to match_array(expected_symbols)
        expect(cached_symbols).to match_array(expected_symbols)
        expect(redis_client.ttl(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY)).to be > 0
      end
    end

    context 'when Redis cache is populated and not expired' do
      before do
        redis_client.sadd(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY, expected_symbols)
        redis_client.expire(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY, 3600)
      end

      it 'returns symbols from Redis without querying the DB' do
        symbols = manager.active_symbols

        expect(mock_threshold_scope).not_to receive(:where)
        expect(symbols).to match_array(expected_symbols)
      end
    end

    context 'when Redis cache is present but expired (TTL = -2)' do
      before do
        redis_client.sadd(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY, [ 'EXPIRED' ])
        redis_client.persist(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY)
        redis_client.expire(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY, 0)
      end

      it 'fetches symbols from DB and overwrites the old cache' do
        symbols        = manager.active_symbols
        cached_symbols = redis_client.smembers(PriceAlerts::SymbolManager::ACTIVE_SYMBOLS_KEY)

        expect(mock_threshold_scope).to receive(:where).and_call_original
        expect(symbols).to match_array(expected_symbols)
        expect(cached_symbols).to match_array(expected_symbols)
      end
    end
  end
end

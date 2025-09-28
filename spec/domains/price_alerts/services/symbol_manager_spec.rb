require 'rails_helper'

# Включаем WebMock, чтобы предотвратить любые случайные сетевые запросы
require 'webmock/rspec'

module PriceAlerts
  RSpec.describe Services::SymbolManager, type: :service do
    # Используем Redis с отдельной базой для тестов
    let(:redis_client) { Redis.new(db: 15) }

    # Запрещаем внешние сетевые вызовы и очищаем Redis перед каждым тестом
    before(:each) do
      # Запрет внешних сетевых вызовов, разрешая только localhost для Redis/DB
      WebMock.disable_net_connect!(allow_localhost: true)
      redis_client.flushdb
    end

    # Создаем реальные записи в базе данных
    let!(:btc_threshold)      { create(:price_threshold, symbol: 'BTCUSDT', is_active: true) }
    let!(:eth_threshold)      { create(:price_threshold, symbol: 'ETHUSDT', is_active: true) }
    let!(:inactive_threshold) { create(:price_threshold, symbol: 'DOGEUSDT', is_active: false) }

    # Инициализация тестируемого сервиса
    let(:manager)              { described_class.new(redis_client: redis_client) }

    # Ожидаемый результат из базы
    let(:expected_symbols)     { [ 'BTCUSDT', 'ETHUSDT' ] }

    # Удаляем неиспользуемый чистый мок, который вызывал ошибку
    # let(:mock_threshold_scope) { class_double('PriceThreshold') }

    describe '#active_symbols' do
      context 'when Redis cache is empty (initial run)' do
        it 'fetches symbols from DB, caches them, and returns the list' do
          # Используем частичный мок на реальном классе PriceThreshold.
          # Это позволяет нам проверить, что .where был вызван, и при этом выполнить
          # оригинальный код (ActiveRecord-запрос) для получения данных.
          expect(PriceThreshold).to receive(:where).and_call_original

          symbols = manager.active_symbols
          cached_symbols = redis_client.smembers(described_class::ACTIVE_SYMBOLS_KEY)

          expect(symbols).to match_array(expected_symbols)
          expect(cached_symbols).to match_array(expected_symbols)
          expect(redis_client.ttl(described_class::ACTIVE_SYMBOLS_KEY)).to be > 0
        end
      end

      context 'when Redis cache is populated and not expired' do
        before do
          redis_client.sadd(described_class::ACTIVE_SYMBOLS_KEY, expected_symbols)
          redis_client.expire(described_class::ACTIVE_SYMBOLS_KEY, 3600)
        end

        it 'returns symbols from Redis without querying the DB' do
          symbols = manager.active_symbols

          # Ожидаем, что метод .where на классе PriceThreshold НЕ будет вызван.
          expect(PriceThreshold).not_to receive(:where)

          expect(symbols).to match_array(expected_symbols)
        end
      end

      context 'when Redis cache is present but expired (TTL = -2)' do
        before do
          redis_client.sadd(described_class::ACTIVE_SYMBOLS_KEY, [ 'EXPIRED' ])
          # Устанавливаем TTL=0, чтобы симулировать "истекший" кеш.
          redis_client.expire(described_class::ACTIVE_SYMBOLS_KEY, 0)
        end

        it 'fetches symbols from DB and overwrites the old cache' do
          # Используем частичный мок на реальном классе PriceThreshold.
          expect(PriceThreshold).to receive(:where).and_call_original

          symbols        = manager.active_symbols
          cached_symbols = redis_client.smembers(described_class::ACTIVE_SYMBOLS_KEY)

          expect(symbols).to match_array(expected_symbols)
          expect(cached_symbols).to match_array(expected_symbols)
          # Также убедимся, что кеш был обновлен и получил новый TTL
          expect(redis_client.ttl(described_class::ACTIVE_SYMBOLS_KEY)).to be > 0
        end
      end
    end
  end
end

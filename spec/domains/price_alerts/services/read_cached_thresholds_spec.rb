require 'rails_helper'
require 'bigdecimal'
require 'json'

# NOTE: Для тестов нам нужна минимальная заглушка PriceThreshold
# Мы будем проверять, что from_cache вызывается с правильными хэшами.
class PriceThreshold
  def self.from_cache(hash)
    # Имитируем создание объекта из хэша
    OpenStruct.new(id: hash[:id], value: hash[:value])
  end
end

module PriceAlerts
  RSpec.describe Services::ReadCachedThresholds do
    # Мокируем клиент Redis
    let(:redis_client) { instance_double(Redis, get: nil) }
    let(:service) { described_class.new(redis_client: redis_client) }
    let(:symbol) { "BTCUSDT" }
    let(:redis_key) { "active_thresholds_by_symbol:BTCUSDT" }

    # Корректные данные, которые ThresholdSyncWorker сохранил в Redis
    let(:cached_json) do
      [
        { id: 1, symbol: "BTCUSDT", value: "70000.0", operator: "up" },
        { id: 2, symbol: "BTCUSDT", value: "65000.0", operator: "down" }
      ].to_json
    end

    # --- 1. Сценарий Успеха: Данные найдены и корректны ---
    context 'when active thresholds are found in Redis' do
      before do
        # Настраиваем мок Redis для возврата корректного JSON
        allow(redis_client).to receive(:get).with(redis_key).and_return(cached_json)
        # Настраиваем спай для PriceThreshold.from_cache
        allow(PriceThreshold).to receive(:from_cache).and_call_original
      end

      it 'returns Success with an array of PriceThreshold objects' do
        result = service.call(symbol)

        expect(result).to be_success
        thresholds = result.value!

        # Проверяем, что вернулся массив
        expect(thresholds).to be_an(Array)
        expect(thresholds.size).to eq(2)

        # Проверяем, что PriceThreshold.from_cache был вызван для каждого элемента
        expect(PriceThreshold).to have_received(:from_cache).twice

        # Проверяем гидратацию первого элемента
        expect(thresholds.first.id).to eq(1)
      end
    end

    # --- 2. Сценарий Отсутствия данных (кеш пуст) ---
    context 'when no data is found in Redis' do
      # По умолчанию redis_client.get возвращает nil, что должно быть обработано
      # как DEFAULT_EMPTY_JSON_ARRAY ("[]")

      it 'returns Success with an empty array' do
        result = service.call(symbol)

        expect(result).to be_success
        expect(result.value!).to be_empty

        # Проверяем, что метод from_cache не вызывался
        expect(PriceThreshold).not_to receive(:from_cache)
      end
    end

    # --- 3. Сценарий Ошибки: Поврежденный кеш ---
    context 'when cached data is corrupted (invalid JSON)' do
      before do
        # Настраиваем мок Redis для возврата невалидного JSON
        allow(redis_client).to receive(:get).with(redis_key).and_return('{ "corrupted": true, ')
      end

      it 'returns Failure and logs the error' do
        # Используем спай для Rails.logger, чтобы проверить логгирование
        expect(Rails.logger).to receive(:error).with(/Failed to parse cached thresholds/)

        result = service.call(symbol)

        expect(result).to be_failure
        expect(result.failure).to eq("Invalid cached data inside Redis")
      end
    end
  end
end

# spec/domains/price_thresholds/services/redis_full_synchronizer_spec.rb

require 'rails_helper'
require 'ostruct'

module PriceThresholds
  RSpec.describe Services::RedisFullSynchronizer, type: :service do
    include Dry::Monads[:result]
    # --- Настройка Зависимостей ---
    # Используем class_double, чтобы быть уверенными, что работаем с моком
    let(:threshold_model_double) { class_double(PriceThreshold) }
    let(:synchronizer_double)    { instance_double(Services::RedisIncrementalSynchronizer) }
    let(:redis_client_double)    { instance_double(Redis) } # Мокаем Redis.new

    # Заглушки данных, которые вернет БД
    let(:threshold_1) { OpenStruct.new(symbol: "BTCUSDT", id: 1) }
    let(:threshold_2) { OpenStruct.new(symbol: "ETHUSDT", id: 2) }
    let(:active_thresholds) { [ threshold_1, threshold_2 ] }

    # Создаем тестируемый объект с внедренными зависимостями
    let(:full_sync) do
      described_class.new(
        threshold_model: threshold_model_double,
        synchronizer: synchronizer_double,
        redis_client: redis_client_double
      )
    end

    # --- Общая настройка успешного делегирования ---
    before do
      # Мокаем, что синхронизатор всегда успешен
      allow(synchronizer_double).to receive(:call).and_return(Success())
      allow(redis_client_double).to receive(:keys).and_return([ 1, 2, 3 ])
      allow(redis_client_double).to receive(:del)
      # Мокаем получение данных из БД для happy path
      allow(threshold_model_double).to receive(:where).with(is_active: true).and_return(active_thresholds)
    end

    # 1. Если ключа нет, удаление не вызывается
    context "when Redis is already clean (no keys)" do
      before do
        allow(redis_client_double).to receive(:keys).and_return([])
      end

      it "fetches data but does NOT call DEL on the Redis client" do
        full_sync.call

        expect(redis_client_double).to have_received(:keys).with("thresholds:active:*").once
        expect(redis_client_double).not_to have_received(:del)
      end
    end

    # 2. Если ключ есть, удаление вызывается
    context "when old Redis keys exist" do
      before do
        # Имитируем, что Redis содержит один старый ключ
        allow(redis_client_double).to receive(:keys).and_return([ "thresholds:active:OLD" ])
        # Мокаем, что del прошел успешно
        allow(redis_client_double).to receive(:del).and_return(1)
      end

      it "calls DEL to clear the old keys" do
        full_sync.call

        expect(redis_client_double).to have_received(:keys).with("thresholds:active:*").once
        expect(redis_client_double).to have_received(:del).with([ "thresholds:active:OLD" ]).once
      end
    end

    # 3, 4, 5. Happy Path: Проверка получения данных, цикла и возвращаемого значения
    context "when all dependencies are successful" do
      # Мы уже настроили threshold_model_double.where возвращать 2 записи в shared 'before'

      it "3. pulls records from the database using is_active: true" do
        full_sync.call
        expect(threshold_model_double).to have_received(:where).with(is_active: true).once
      end

      it "4. calls the Synchronizer service exactly for each record" do
        full_sync.call

        # Проверяем, что делегирование было вызвано для каждой записи
        expect(synchronizer_double).to have_received(:call).with(threshold_1).once
        expect(synchronizer_double).to have_received(:call).with(threshold_2).once
        # Проверяем, что не было никаких других вызовов
        expect(synchronizer_double).to have_received(:call).twice
      end

      it "5. returns Success() with an empty result" do
        result = full_sync.call

        expect(result).to be_success
        expect(result.value!).to eq active_thresholds
      end
    end

    # 6. Кейс, где мы ловим ошибку и возвращаем фейл
    context "when a dependency raises an exception" do
      let(:error_message) { "Database connection timed out" }

      # Имитируем, что БД недоступна (ActiveRecord::StatementInvalid)
      before do
        allow(redis_client_double).to receive(:keys).and_return([]) # Очистка проходит
        allow(threshold_model_double).to receive(:where)
          .and_raise(ActiveRecord::StatementInvalid, error_message)
      end

      it "rescues the exception and returns Failure with a descriptive message" do
        result = full_sync.call

        expect(result).to be_failure
        expect(result.failure).to eq("FullSync failed: #{error_message}")

        # Проверяем, что делегирование не было вызвано
        expect(synchronizer_double).not_to have_received(:call)
      end
    end
  end
end

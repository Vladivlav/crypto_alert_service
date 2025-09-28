# spec/services/price_thresholds/redis_synchronizer_spec.rb

require "spec_helper"
require_relative '../../../app/services/price_thresholds/redis_synchronizer'

RSpec.describe PriceThresholds::RedisSynchronizer do
  # 1. Мокирование зависимостей
  let(:redis_client) { instance_double(Redis) }
  let(:synchronizer) { described_class.new(redis_client: redis_client) }

  # Создаем тестовый объект, имитирующий threshold
  let(:threshold) do
    instance_double(
      "Threshold",
      symbol: "BTCUSDT",
      to_redis_data: { "price": 60000, "level": "high" }
    )
  end

  # Ожидаемый ключ, который должен быть сгенерирован
  let(:expected_redis_key) { "thresholds:active:BTCUSDT" }
  # Ожидаемое значение, которое должно быть передано
  let(:expected_redis_data) { threshold.to_redis_data.to_json }

  describe "#call" do
    subject { synchronizer.call(threshold) }

    it "правильно формирует ключ и вызывает rpush на Redis-клиенте" do
      # 2. Ожидание вызова (Expectation)
      # Мы ожидаем, что метод rpush будет вызван один раз с правильными аргументами
      expect(redis_client).to receive(:rpush)
        .with(expected_redis_key, expected_redis_data)
        .and_return(1) # Redis rpush возвращает длину списка

      # 3. Выполнение (Execution)
      subject
    end

    it "возвращает Success(true) независимо от результата Redis" do
      # Чтобы не было ошибок при выполнении теста, мы должны заглушить rpush
      allow(redis_client).to receive(:rpush).and_return(1)

      # 4. Проверка результата (Assertion)
      expect(subject).to be_a_success
      expect(subject.value!).to eq(true)
    end
  end
end

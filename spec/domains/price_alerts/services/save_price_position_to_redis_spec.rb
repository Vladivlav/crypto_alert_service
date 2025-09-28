require 'rails_helper'
require 'dry/monads'

module PriceAlerts
  module Services
    RSpec.describe SavePricePositionToRedis do
      include Dry::Monads[:result]

      # Задаем базовые значения для тестируемого порога
      let(:threshold_id)    { 123 }
      let(:threshold_value) { 69_500.00 }

      # ИСПОЛЬЗУЕМ КОРРЕКТНУЮ ФАБРИКУ: build(:price_threshold)
      let(:threshold) do
        # FactoryBot.build создает объект модели PriceThreshold с нужными атрибутами
        build(:price_threshold, value: threshold_value, id: threshold_id)
      end

      # Mock клиента Redis
      let(:redis_client)  { instance_double(Redis) }

      # Ожидаемый формат ключа Redis, определенный в сервисе
      let(:expected_key) { "threshold_state:#{threshold_id}" }

      # Вспомогательный метод для создания экземпляра сервиса с определенной ценой
      def initialize_service(price)
        described_class.new(
          threshold: threshold,
          current_price: price,
          redis_client: redis_client
        )
      end

      context 'when successful' do
        let(:redis_response) { "OK" } # Стандартный ответ Redis для SET

        before do
          allow(redis_client).to receive(:set).and_return(redis_response)
        end

        context 'when current price is ABOVE the threshold (70,000)' do
          let(:price) { 70_000.00 }
          let(:service) { initialize_service(price) }

          it 'sets state to "ABOVE" with the correct key and returns Success' do
            # Ожидаем, что Redis будет вызван с новым форматом ключа и состоянием 'ABOVE'
            expect(redis_client).to receive(:set).once.with(expected_key, described_class::STATE_ABOVE)

            result = service.call
            expect(result).to be_success
            expect(result.value!).to eq(redis_response)
          end
        end

        context 'when current price is BELOW the threshold (69,499.99)' do
          let(:price) { 69_499.99 }
          let(:service) { initialize_service(price) }

          it 'sets state to "BELOW" with the correct key and returns Success' do
            # Ожидаем, что Redis будет вызван с новым форматом ключа и состоянием 'BELOW'
            expect(redis_client).to receive(:set).once.with(expected_key, described_class::STATE_BELOW)

            result = service.call
            expect(result).to be_success
            expect(result.value!).to eq(redis_response)
          end
        end

        context 'when current price is EXACTLY equal to the threshold (69,500.00)' do
          let(:price) { 69_500.00 }
          let(:service) { initialize_service(price) }

          # Поскольку используется >=, равная цена считается "ABOVE"
          it 'sets state to "ABOVE" and returns Success' do
            expect(redis_client).to receive(:set).once.with(expected_key, described_class::STATE_ABOVE)

            result = service.call
            expect(result).to be_success
            expect(result.value!).to eq(redis_response)
          end
        end
      end

      context 'when Redis connection fails' do
        let(:price) { 70_000.00 }
        let(:service) { initialize_service(price) }

        before do
          # Симулируем ошибку подключения во время операции SET
          allow(redis_client).to receive(:set).and_raise(Redis::CannotConnectError.new("Connection timed out"))
        end

        it 'returns a Failure with a specific error message' do
          result = service.call
          expect(result).to be_failure
          expect(result.failure).to eq("Can not connect to Redis")
        end
      end
    end
  end
end

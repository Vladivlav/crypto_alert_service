# spec/domains/price_thresholds/scenarios/create_spec.rb

require "rails_helper"

module PriceThresholds
  RSpec.describe Scenarios::Create do
    # --- 1. Мокирование зависимостей ---
    let(:model_klass)      { class_double(PriceThreshold) }
    let(:pair_model_klass) { class_double(CryptoPair) }
    let(:redis_synchronizer) { instance_double(Services::RedisIncrementalSynchronizer) }

    # Создаем экземпляр сервиса, внедряя моки
    subject(:creator) do
      described_class.new(
        model_klass: model_klass,
        pair_model_klass: pair_model_klass,
        redis_synchronizer: redis_synchronizer
      )
    end

    # Общие данные для вызова
    let(:params) { { symbol: "ETHUSDT", value: "3500.00", operator: ">" } }

    # Мок объекта, который должен быть возвращен после создания
    let(:created_threshold) { instance_double("PriceThreshold") }

    # ---

    describe "#call" do
      let(:final_data_to_create) do
        {
          symbol: "ETHUSDT",
          value: BigDecimal("3500.00"),
          operator: ">",
          is_active: true
        }
      end

      # --- Сценарий 1: Ошибка лимита ---
      context "когда превышен лимит активных заявок" do
        before do
          # 1. Заглушаем user_has_capacity? на FALSE
          allow(model_klass).to receive(:user_has_capacity?).and_return(false)
        end

        it "возвращает Failure с сообщением о лимите" do
          expect(creator.call(params)).to be_failure
          expect(creator.call(params).failure).to eq("Превышен лимит активных заявок.")
        end

        it "не обращается к другим зависимостям" do
          # Убеждаемся, что код обрывается рано и не вызывает никаких других методов
          expect(pair_model_klass).not_to receive(:exists?)
          expect(model_klass).not_to receive(:create!)
          creator.call(params)
        end
      end

      # --- Сценарий 2: Ошибка символа ---
      context "когда символ не существует" do
        before do
          # 1. Разрешаем user_has_capacity? (TRUE)
          allow(model_klass).to receive(:user_has_capacity?).and_return(true)
          # 2. Заглушаем exists? на FALSE
          allow(pair_model_klass).to receive(:exists?).and_return(false)
        end

        it "возвращает Failure с сообщением о символе" do
          expect(creator.call(params)).to be_failure
          expect(creator.call(params).failure).to eq("Символ не существует в списке отслеживаемых криптопар.")
        end

        it "не создает и не синхронизирует заявку" do
          expect(model_klass).not_to receive(:create!)
          expect(redis_synchronizer).not_to receive(:call)
          creator.call(params)
        end
      end

      # --- Сценарий 3: Успешное создание ---
      context "при успешной проверке всех лимитов и данных" do
        before do
          # Разрешаем все проверки
          allow(model_klass).to receive(:user_has_capacity?).and_return(true)
          allow(pair_model_klass).to receive(:exists?).and_return(true)
        end

        it "создает запись, синхронизирует ее и возвращает Success" do
          # Ожидаем вызова create! с правильно подготовленными данными
          expect(model_klass).to receive(:create!)
            .with(final_data_to_create)
            .and_return(created_threshold)

          # Ожидаем синхронизации в Redis
          expect(redis_synchronizer).to receive(:call)
            .with(created_threshold)

          # Проверяем конечный результат
          result = creator.call(params)
          expect(result).to be_a_success
          expect(result.value!).to eq(created_threshold)
        end
      end
    end
  end
end

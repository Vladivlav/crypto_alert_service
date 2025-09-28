require 'rails_helper'
require 'dry/monads'

RSpec.describe "PriceThresholds", type: :request do
  include Dry::Monads[:result]

  describe "POST /api/v1/price_thresholds" do
    # Мокируем внешние зависимости сервиса PriceThresholds::Create
    let(:price_threshold_klass) { class_double(PriceThreshold) }
    let(:crypto_pair_klass)     { class_double(CryptoPair) }
    let(:redis_synchronizer)    { class_double(PriceThresholds::RedisSynchronizer) }

    # Параметры, которые будут отправлены
    let(:valid_params_hash) do
      { symbol: "BTCUSDT", value: "65000", operator: "down" }
    end

    let(:request_params) do
      { price_threshold: valid_params_hash }
    end

    # Создаем mock-объект, который должен быть создан в БД
    let(:mock_created_threshold) do
      instance_double("PriceThreshold", id: 101, symbol: "BTCUSDT")
    end

    # Настраиваем моки для сервиса Create, которые используются в каждом контексте
    before do
      # Важно: Здесь мы заменяем константы класса PriceThresholds::Create на наши моки
      stub_const("PriceThreshold", price_threshold_klass)
      stub_const("CryptoPair", crypto_pair_klass)
      stub_const("PriceThresholds::RedisSynchronizer", redis_synchronizer)
    end

    # --- Сценарий 1: Успешное создание ---
    context "when all checks pass (Happy Path)" do
      before do
        # Разрешаем проверки: емкость и существование пары
        allow(price_threshold_klass).to receive(:user_has_capacity?).and_return(true)
        allow(crypto_pair_klass).to receive(:exists?).and_return(true)
        allow(redis_synchronizer).to receive(:call).and_return(true)

        # Настраиваем успешное создание в БД
        allow(price_threshold_klass).to receive(:create!)
          .and_return(mock_created_threshold)
      end

      it "creates a new PriceThreshold record and returns 201 status" do
        # Проверяем изменение количества записей в БД
        expect(price_threshold_klass).to receive(:create!)

        post "/api/v1/price_thresholds", params: request_params, as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq("Price threshold created successfully")
      end
    end

    # --- Сценарий 2: Провал валидации (проверяем работу формы) ---
    context "when parameters are invalid (e.g., missing value)" do
      let(:invalid_params) do
        { price_threshold: { symbol: "BTCUSDT", operator: ">" } } # 'value' отсутствует
      end

      # Примечание: Здесь мы полагаемся на реальную работу PriceThresholds::CreateContract
      # и предполагаем, что он вернет ошибку.

      it "returns a 422 status and a validation error" do
        post "/api/v1/price_thresholds", params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)

        # Предполагаем, что сообщение об ошибке формы будет примерно таким
        expect(json_response['errors']).to be_present
        expect(json_response['errors'].keys).to include('value')
      end
    end

    # --- Сценарий 3: Провал бизнес-логики (проверяем работу сценария) ---
    context "when user has exceeded the capacity limit" do
      before do
        # Имитируем ошибку лимита
        allow(price_threshold_klass).to receive(:user_has_capacity?).and_return(false)
        allow(crypto_pair_klass).to receive(:exists?).and_return(true) # Разрешаем символ
      end

      it "returns a 422 status and the business error message" do
        post "/api/v1/price_thresholds", params: request_params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)

        # Проверяем сообщение об ошибке, которое вернет сервис
        expect(json_response['error']).to eq(PriceThresholds::Create::MAX_LIMIT_ERROR_MSG)
      end
    end
  end
end

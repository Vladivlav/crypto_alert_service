require 'rails_helper'
require "ostruct"

RSpec.describe Api::V1::PriceThresholdsController, type: :controller do
  describe "POST create" do
    # Мокируем экземпляры контракта и сценария
    let(:form_double) { instance_double(PriceThresholds::Contracts::Create) }
    let(:scenario_double) { instance_double(PriceThresholds::Scenarios::Create) }

    # Мокируем инициализацию, чтобы всегда возвращать наши двойники
    before do
      allow(PriceThresholds::Contracts::Create).to receive(:new).and_return(form_double)
      allow(PriceThresholds::Scenarios::Create).to receive(:new).and_return(scenario_double)
    end

    # Общие параметры, которые придут в запросе
    let(:valid_input_params) do
      { symbol: "BTCUSDT", value: "65000", operator: ">" }
    end

    # Параметры запроса, включая корневой ключ
    let(:request_params) do
      { price_threshold: valid_input_params }
    end

    # Результаты моков в виде простых структур (Dry::Monads-подобные ответы)

    # Успешный результат валидации
    let(:successful_form_result) do
      OpenStruct.new(success?: true, to_h: valid_input_params)
    end

    # Неудачный результат валидации (например, 'value' is missing)
    let(:failed_form_result) do
      OpenStruct.new(
        success?: false,
        errors: { value: [ "must be a number" ] },
        to_h: valid_input_params.merge(value: "invalid")
      )
    end

    # Успешный результат бизнес-логики (Service)
    let(:successful_scenario_result) do
      OpenStruct.new(success?: true, value!: { id: 1, symbol: "BTCUSDT" })
    end

    # Неудачный результат бизнес-логики (Service)
    let(:failed_scenario_result) do
      OpenStruct.new(success?: false, failure: "Превышен лимит активных заявок.")
    end

    context "when input is valid (happy path)" do
      before do
        # 1. Валидация успешна
        allow(form_double).to receive(:call).and_return(successful_form_result)
        # 2. Сценарий успешен
        allow(scenario_double).to receive(:call).and_return(successful_scenario_result)
      end

      it "responds with a 201 status and a success message" do
        post :create, params: request_params, as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Price threshold created successfully')
      end
    end

    context "when parameters are invalid (Validation Failure)" do
      before do
        # 1. Валидация провалена
        allow(form_double).to receive(:call).and_return(failed_form_result)
      end

      it "responds with a 422 status and a validation error" do
        post :create, params: request_params, as: :json
        # Предполагаем, что validate_params! рендерит 422
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to eq('value' => [ 'must be a number' ])
      end
    end

    context "when the scenario/service fails (Business Logic Failure)" do
      before do
        # 1. Валидация успешна
        allow(form_double).to receive(:call).and_return(successful_form_result)
        # 2. Сценарий провален
        allow(scenario_double).to receive(:call).and_return(failed_scenario_result)
      end

      it "responds with a 422 status and a service error message" do
        post :create, params: request_params, as: :json
        # Предполагаем, что check_result! рендерит 422
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to eq('Превышен лимит активных заявок.')
      end
    end
  end
end

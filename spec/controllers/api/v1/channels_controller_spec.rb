# spec/controllers/api/v1/channels_controller_spec.rb
require 'rails_helper'
require "ostruct"

RSpec.describe Api::V1::ChannelsController, type: :controller do
  describe "POST create" do
    let(:contract_double) { instance_double(NotificationChannels::Contracts::Telegram) }
    let(:service_double) { instance_double(NotificationChannels::Scenarios::CreateTelegramChannel) }

    # Мокируем контракт и сервис
    let(:telegram_factory_config) do
      {
        contract: instance_double(Class, new: contract_double),
        scenario: instance_double(Class, new: service_double)
      }
    end

    # Результаты моков в виде простых структур
    let(:valid_params) do
      { channel_type: 'telegram', token: 'valid_telegram_token' }
    end

    let(:successful_contract_result) do
      OpenStruct.new(success?: true, to_h: valid_params)
    end

    let(:failed_contract_result) do
      OpenStruct.new(
        success?: false,
        errors: { token: [ "is missing" ] },
        to_h: { token: "" }
      )
    end

    let(:successful_service_result) do
      OpenStruct.new(success?: true, value!: { name: "Test Channel", token: "valid_telegram_token" })
    end

    let(:failed_service_result) do
      OpenStruct.new(success?: false, failure: "Failed to save channel")
    end

    before do
      allow(ChannelCreation).to receive(:for).and_return(telegram_factory_config)
    end

    context "when input is valid (happy path)" do
      before do
        allow(contract_double).to receive(:call).and_return(successful_contract_result)
        allow(service_double).to receive(:call).and_return(successful_service_result)
      end

      it "responds with a 201 status and a success message" do
        post :create, params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Channel created successfully')
      end
    end

    context "when input is invalid (unsupported channel type)" do
      let(:invalid_channel_type_params) { { channel_type: 'telegram', token: 'some_token' } }

      before do
        allow(ChannelCreation).to receive(:for).and_raise(
          Errors::InvalidChannelType, "Unsupported channel type: sms"
        )
      end

      it "responds with a 400 status and an error message" do
        post :create, params: invalid_channel_type_params, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Unsupported channel type: sms')
      end
    end

    context "when parameters are invalid" do
      before do
        allow(contract_double).to receive(:call).and_return(failed_contract_result)
      end

      it "responds with a 422 status and a validation error" do
        post :create, params: { channel_type: 'telegram', token: '' }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to eq('token' => [ 'is missing' ])
      end
    end

    context "when the service fails" do
      before do
        allow(contract_double).to receive(:call).and_return(successful_contract_result)
        allow(service_double).to receive(:call).and_return(failed_service_result)
      end

      it "responds with a 422 status and a service error" do
        post :create, params: valid_params, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to eq('Failed to save channel')
      end
    end
  end
end

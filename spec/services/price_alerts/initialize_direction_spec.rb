require 'rails_helper'
require 'dry/monads'
require_relative '../../../app/services/price_alerts/initialize_direction'

RSpec.describe PriceAlerts::InitializeDirection do
  include Dry::Monads[:result]

  let(:redis_client)         { instance_double(Redis) }
  let(:initialize_direction) { described_class.new(redis_client: redis_client) }

  let(:key)             { "alert:btc_usdt:69500" }
  let(:threshold_value) { 69_500.00 }
  let(:threshold)       { instance_double('Alert', value: threshold_value) }

  before do
    allow(redis_client).to receive(:set)
  end

  context 'when current price is ABOVE the threshold' do
    let(:price) { 70_000.00 }

    it 'sets state to "ABOVE" in Redis and returns Success("ABOVE")' do
      expect(redis_client).to receive(:set).once.with(key, "ABOVE")

      result = initialize_direction.call(price, key, threshold)
      expect(result).to be_success
      expect(result.value!).to eq("ABOVE")
    end
  end

  context 'when current price is BELOW the threshold' do
    let(:price) { 69_499.99 }

    it 'sets state to "BELOW" in Redis and returns Success("BELOW")' do
      expect(redis_client).to receive(:set).once.with(key, "BELOW")

      result = initialize_direction.call(price, key, threshold)
      expect(result).to be_success
      expect(result.value!).to eq("BELOW")
    end
  end

  context 'when current price is EXACTLY equal to the threshold' do
    let(:price) { 69_500.00 }

    it 'sets state to "ABOVE" and returns Success("ABOVE")' do
      expect(redis_client).to receive(:set).once.with(key, "ABOVE")

      result = initialize_direction.call(price, key, threshold)
      expect(result).to be_success
      expect(result.value!).to eq("ABOVE")
    end
  end
end

require 'rails_helper'
require 'dry/monads'

RSpec.describe PriceAlerts::HandleFallingPrice do
  include Dry::Monads[:result]

  let(:redis_client)         { instance_double(Redis) }
  let(:notification_service) { instance_double('Notifications::SendNotificationService', call: Success()) }

  let(:handler) {
    described_class.new(
      redis_client: redis_client,
      send_notifications_service: notification_service
    )
  }

  let(:key)             { "alert:btc_usdt:69500" }
  let(:threshold_value) { 69_500.00 }
  let(:threshold)       { instance_double('PriceThreshold', value: threshold_value) }

  before do
    allow(redis_client).to receive(:set).and_return(true)
  end

  context 'when price crosses the threshold from ABOVE ("ABOVE" -> "BELOW")' do
    let(:price) { 69_000.00 }
    let(:state) { "ABOVE" }

    it 'sends notification, updates Redis to "BELOW", and returns Success()' do
      expect(notification_service).to receive(:call).once.with(threshold)

      expect(redis_client).to receive(:set).once.with(key, "BELOW")

      result = handler.call(price, key, threshold, state)
      expect(result).to be_success
    end
  end

  context 'when price rises back into the reset zone ("BELOW" -> "ABOVE")' do
    let(:price) { 69_500.01 }
    let(:state) { "BELOW" } # Алерт сработал и ждет сброса

    it 'does NOT send notification, updates Redis to "ABOVE", and returns Success()' do
      # Проверяем, что УВЕДОМЛЕНИЕ НЕ ОТПРАВЛЕНО
      expect(notification_service).not_to receive(:call)

      # Проверяем, что Redis обновлен для сброса
      expect(redis_client).to receive(:set).once.with(key, "ABOVE")

      result = handler.call(price, key, threshold, state)
      expect(result).to be_success
    end
  end

  context 'when price is far below threshold and state is already BELOW' do
    let(:state) { "BELOW" }
    let(:price) { 60_000.00 }

    it 'does not interact with Redis or Notifier, and returns Success()' do
      expect(notification_service).not_to receive(:call)
      expect(redis_client).not_to receive(:set)

      result = handler.call(price, key, threshold, state)
      expect(result).to be_success
    end
  end

  context 'when price is far above threshold and state is already ABOVE' do
    let(:state) { "ABOVE" }
    let(:price) { 70_500.00 }

    it 'does not interact with Redis or Notifier, and returns Success()' do
      expect(notification_service).not_to receive(:call)
      expect(redis_client).not_to receive(:set)

      result = handler.call(price, key, threshold, state)
      expect(result).to be_success
    end
  end
end

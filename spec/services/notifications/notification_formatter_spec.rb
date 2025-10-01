# spec/services/notifications/notification_formatter_spec.rb

require 'rails_helper'

RSpec.describe Notifications::NotificationFormatter do
  let(:formatter) { described_class.new.call(threshold) }

  context 'when threshold operator is "up"' do
    let(:threshold) { create :price_threshold, operator: "up" }

    it 'generates a message indicating the price is higher than the threshold' do
      expect(formatter).to eq("Price of the cryptopair BTCUSDT become higher than price of #{threshold.value}.")
    end
  end

  context 'when threshold operator is "down"' do
    let(:threshold) { create :price_threshold, operator: "down", symbol: "ETHUSDT" }

    it 'generates a message indicating the price is lower than the threshold' do
      expect(formatter).to eq("Price of the cryptopair ETHUSDT become lower than price of #{threshold.value}.")
    end
  end
end

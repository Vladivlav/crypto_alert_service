# spec/builders/channel_creation_spec.rb

require "rails_helper"
require_relative "../../app/errors/invalid_channel_type"

RSpec.describe ChannelCreation, type: :builder do
  context 'when params contain channel type available for creation' do
    context 'when it is a Telegram channel' do
      it 'returns a contract and a scenario for Telegram channel' do
        result = described_class.for('telegram')

        expect(result[:contract]).to eq(NotificationChannels::Contracts::Telegram)
        expect(result[:scenario]).to eq(NotificationChannels::Scenarios::CreateTelegramChannel)
      end
    end
  end

  context 'when channel type is unsupported' do
    it 'raises and error Errors::InvalidChannelType' do
      expect {
        described_class.for('random_channel')
      }.to raise_error(Errors::InvalidChannelType, 'Unsupported channel type: random_channel')
    end
  end

  context 'when channel type is empty in params' do
    it 'raises and error Errors::InvalidChannelType' do
      expect {
        described_class.for('')
      }.to raise_error(Errors::InvalidChannelType, 'Unsupported channel type: ')
    end
  end
end

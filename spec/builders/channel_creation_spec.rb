# spec/builders/channel_creation_spec.rb

require "rails_helper"
require_relative "../../app/errors/invalid_channel_type"

RSpec.describe ChannelCreation, type: :builder do
  context 'когда тип канала поддерживается' do
    it 'возвращает правильные классы для "telegram"' do
      result = described_class.for('telegram')

      expect(result[:contract]).to eq(TelegramToken)
      expect(result[:service]).to eq(AddTelegramChannel)
    end
  end

  context 'когда тип канала не поддерживается' do
    it 'выбрасывает Errors::InvalidChannelType для невалидного типа' do
      expect {
        described_class.for('random_channel')
      }.to raise_error(Errors::InvalidChannelType, 'Unsupported channel type: random_channel')
    end

    it 'выбрасывает Errors::InvalidChannelType для пустого значения' do
      expect {
        described_class.for('')
      }.to raise_error(Errors::InvalidChannelType, 'Unsupported channel type: ')
    end
  end
end

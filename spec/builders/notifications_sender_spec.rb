require 'rails_helper'
require 'dry/monads'
require_relative "../../app/builders/notifications_sender"
require_relative "../../app/domains/notification_channels/services/telegram/send_message"

RSpec.describe Builders::NotificationSender do
  include Dry::Monads[:result]

  before do
    stub_const('ChannelCreation::TYPES', [ 'email', 'telegram' ])
  end

  let(:email_sender) { class_double(Email::SendMessage) }
  let(:telegram_sender) { class_double(NotificationChannels::Services::Telegram::SendMessage) }
  let(:sms_sender) { class_double(Sms::SendMessage) } # Этот класс не в TYPES, но нужен для проверки 'else'

  before do
    stub_const('Notifications::Email::SendMessage', email_sender)
    stub_const('Notifications::Telegram::SendMessage', telegram_sender)
    stub_const('Notifications::Sms::SendMessage', sms_sender)
  end

  context 'when given a supported and implemented channel type' do
    it 'returns Success with an instance of Notifications::Telegram::SendMessage for "telegram"' do
      result = described_class.new.call('telegram')

      expect(result).to be_success
      expect(result.value!).to eq(telegram_sender)
    end
  end

  context 'when given an unsupported channel type (not in TYPES)' do
    it 'returns Failure with an "Unsupported notification channel type" message' do
      result = described_class.new.call('fax')

      expect(result).to be_failure
      expect(result.failure).to include('Unsupported notification channel type: fax')
    end
  end

  context 'when the type is in TYPES but not implemented in the case statement' do
    before do
      stub_const('ChannelCreation::TYPES', [ 'email', 'telegram', 'sms', 'new_unimplemented' ])
    end

    it 'returns Success for "sms" if implementation is present' do
      result = described_class.new.call('sms')
      expect(result).to be_success
      expect(result.value!).to eq(sms_sender)
    end

    it 'returns Failure with "The channel is not implemented" if present in TYPES but missing implementation' do
      result = described_class.new.call('new_unimplemented')

      expect(result).to be_failure
      expect(result.failure).to eq("Unsupported notification channel type: new_unimplemented")
    end
  end
end

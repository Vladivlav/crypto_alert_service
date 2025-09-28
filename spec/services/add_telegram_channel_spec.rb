# spec/services/add_telegram_channel_service_spec.rb
require 'rails_helper'
require 'dry/monads'

RSpec.describe AddTelegramChannel, type: :service do
  let(:token)         { "valid_token" }
  let(:invalid_token) { "invalid_token" }

  # Моки теперь ожидают токен в методе call
  let(:valid_validator)    { instance_double(TelegramValidator) }
  let(:invalid_validator)  { instance_double(TelegramValidator) }
  let(:successful_webhook) { instance_double(TelegramWebhook) }
  let(:failed_webhook)     { instance_double(TelegramWebhook) }

  # Мок для NotificationChannel
  let(:channel_model) { class_double(NotificationChannel).as_stubbed_const }

  before do
    # Настраиваем моки
    allow(valid_validator).to receive(:call).with(token).and_return(Dry::Monads::Success())
    allow(invalid_validator).to receive(:call).with(invalid_token).and_return(Dry::Monads::Failure("Invalid token"))
    allow(successful_webhook).to receive(:call).and_return(Dry::Monads::Success())
    allow(failed_webhook).to receive(:call).and_return(Dry::Monads::Failure("Webhook failed"))
    allow(channel_model).to receive(:create).and_return(double(persisted?: true))
  end

  it 'возвращает Success, когда все шаги успешны' do
    service = described_class.new(validator: valid_validator, webhook_service: successful_webhook, channel_model: channel_model)

    result = service.call(token: token)

    expect(result).to be_a(Dry::Monads::Success)
  end

  it 'возвращает Failure, когда токен невалиден' do
    service = described_class.new(validator: invalid_validator)

    result = service.call(token: invalid_token)

    expect(result).to be_a(Dry::Monads::Failure)
    expect(result.failure).to eq("Invalid token")
  end

  it 'возвращает Failure, когда установка вебхука провалилась' do
    allow(channel_model).to receive(:create).and_return(double(persisted?: true))
    service = described_class.new(validator: valid_validator, webhook_service: failed_webhook, channel_model: channel_model)

    result = service.call(token: token)

    expect(result).to be_a(Dry::Monads::Failure)
    expect(result.failure).to eq("Webhook failed")
  end
end

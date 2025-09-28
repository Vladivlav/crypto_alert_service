FactoryBot.define do
  factory :notification_channel do
    is_active { true }

    factory :email_channel do
      channel_type { 'email' }
      config { { email_address: Faker::Internet.email } }
      is_active { true }
    end

    factory :telegram_channel do
      channel_type { 'telegram' }
      config { { chat_id: Faker::Number.number(digits: 10).to_s } }
      is_active { false }
    end

    factory :web_push_channel do
      channel_type { 'web_push' }
      config do
        {
          endpoint: Faker::Internet.url,
          keys: {
            auth: Faker::Alphanumeric.alphanumeric(number: 16),
            p256dh: Faker::Alphanumeric.alphanumeric(number: 16)
          }
        }
      end
      is_active { true }
    end

    # Добавляем фабрику для канала логов
    factory :log_channel do
      channel_type { 'log' }
      config { {} } # У канала логов нет специальной конфигурации
      is_active { true }
    end
  end
end

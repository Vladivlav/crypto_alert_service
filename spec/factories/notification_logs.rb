FactoryBot.define do
  factory :notification_log do
    channel_type { 'email' }
    status { 'sent' }
    message { { message: 'Price threshold exceeded' } }
  end
end

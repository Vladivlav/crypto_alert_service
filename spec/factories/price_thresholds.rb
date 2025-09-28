FactoryBot.define do
  factory :price_threshold do
    value { 50000.0 }
    operator { 'up' }
    symbol { 'BTCUSDT' }
    is_active { true }
  end
end

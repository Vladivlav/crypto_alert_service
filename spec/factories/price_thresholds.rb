FactoryBot.define do
  factory :price_threshold do
    association :crypto_pair, factory: :btc_usdt
    value { 50000.0 }
    operator { 'gt' }
    is_active { true }
  end
end

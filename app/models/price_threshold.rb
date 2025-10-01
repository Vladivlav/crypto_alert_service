class PriceThreshold < ApplicationRecord
  MAX_ACTIVE_THRESHOLDS = 1000

  def self.user_has_capacity?
    where(is_active: true).count < MAX_ACTIVE_THRESHOLDS
  end

  def to_redis_data
    {
      value: value.to_s,
      operator: operator
    }
  end

  def self.from_cache(hash)
    threshold = self.new

    threshold.id       = hash[:id]
    threshold.symbol   = hash[:symbol]
    threshold.value    = BigDecimal(hash[:value].to_s)
    threshold.operator = hash[:operator]
    threshold
  end
end

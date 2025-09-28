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
end

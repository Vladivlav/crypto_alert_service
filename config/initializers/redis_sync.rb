# Обязательно загружаем гем
require "redis"

if defined?(Rails) && !Rails.env.test?
  Rails.application.config.after_initialize do
    PriceThresholds::Services::RedisFullSynchronizer.new.call
  end
end

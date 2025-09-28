# app/domains/price_alerts/services/symbol_manager.rb

module PriceAlerts
  module Services
    class SymbolManager
      ACTIVE_SYMBOLS_KEY = "price_alerts:symbols"
      CACHE_TTL          = 60.minutes

      def initialize(redis_client: Sidekiq.redis { |conn| conn })
        @redis_client = redis_client
      end

      def active_symbols
        symbols_from_redis = redis_client.smembers(ACTIVE_SYMBOLS_KEY)

        if symbols_from_redis.any? && redis_client.ttl(ACTIVE_SYMBOLS_KEY) != -2
          return symbols_from_redis
        end

        sync_from_db_and_set_cache
      end

      private

      attr_reader :redis_client

      def sync_from_db_and_set_cache
        unique_symbols = PriceThreshold.where(is_active: true).distinct.pluck(:symbol)

        redis_client.del(ACTIVE_SYMBOLS_KEY)
        if unique_symbols.any?
          redis_client.sadd(ACTIVE_SYMBOLS_KEY, unique_symbols)
        end

        # Устанавливаем срок жизни, чтобы кеш периодически обновлялся
        redis_client.expire(ACTIVE_SYMBOLS_KEY, CACHE_TTL)

        unique_symbols
      end
    end
  end
end

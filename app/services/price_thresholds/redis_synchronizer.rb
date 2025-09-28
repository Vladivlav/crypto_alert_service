# app/services/price_thresholds/redis_synchronizer.rb
require "json"
require "dry/monads"

module PriceThresholds
  class RedisSynchronizer
    include Dry::Monads[:result]

    SYNC_KEY_PREFIX = "thresholds:active:"

    def initialize(redis_client: RedisGlobalClient)
      @redis_client = redis_client
    end

    def self.call(threshold)
      new.call(threshold)
    end

    def call(threshold)
      redis_key = SYNC_KEY_PREFIX + threshold.symbol

      redis_client.rpush(redis_key, threshold.to_redis_data.to_json)
      Success(true)
    end

    private

    attr_reader :redis_client
  end
end

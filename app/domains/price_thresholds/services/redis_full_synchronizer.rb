# app/domains/price_thresholds/services/redis_full_sync.rb

require "dry/monads"

module PriceThresholds
  module Services
    class RedisFullSynchronizer
      include Dry::Monads[:result]

      SYNC_KEY_PREFIX = RedisIncrementalSynchronizer::SYNC_KEY_PREFIX

      def initialize(
        threshold_model: PriceThreshold,
        synchronizer: RedisIncrementalSynchronizer.new,
        redis_client: RedisGlobalClient
      )
        @threshold_model = threshold_model
        @synchronizer    = synchronizer
        @redis_client    = redis_client
      end

      def call
        clear_all_redis_keys!

        active_thresholds = threshold_model.where(is_active: true)

        active_thresholds.each { |threshold| synchronizer.call(threshold) }

        Success(active_thresholds)
      rescue => e
        Failure("FullSync failed: #{e.message}")
      end

      private

      attr_reader :threshold_model, :synchronizer, :redis_client

      def clear_all_redis_keys!
        keys_to_delete = redis_client.keys("#{SYNC_KEY_PREFIX}*")

        redis_client.del(keys_to_delete) if keys_to_delete.any?
      end
    end
  end
end

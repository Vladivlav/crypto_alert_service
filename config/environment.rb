# Load the Rails application.
require_relative "application"
require "redis"

RedisGlobalClient = Redis.new(url: ENV["REDIS_URL"])

# Initialize the Rails application.
Rails.application.initialize!

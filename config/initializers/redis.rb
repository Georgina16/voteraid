# used to initialize Redis for key-value store (replacing usage of twilio phone sessions)
require "redis"

$redis = Redis.new(url: ENV['REDIS_URL'])

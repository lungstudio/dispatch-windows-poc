# frozen_string_literal: true

class RedisHelper
  class << self
    def create_new_client
      ENV['REDISCLOUD_URL'] ? Redis.new(url: ENV['REDISCLOUD_URL']) : Redis.new
    end
  end
end

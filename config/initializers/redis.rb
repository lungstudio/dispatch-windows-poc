# frozen_string_literal: true

NEW_REDIS_CLIENT = ENV['REDISCLOUD_URL'] ? Redis.new(url: ENV['REDISCLOUD_URL']) : Redis.new

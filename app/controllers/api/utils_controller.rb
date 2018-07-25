# frozen_string_literal: true

class Api::UtilsController < ApplicationController
  def flush_redis
    redis = RedisHelper.create_new_client
    redis.flushall
  ensure
    redis.close
  end
end

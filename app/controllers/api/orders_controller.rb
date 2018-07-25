# frozen_string_literal: true

class Api::OrdersController < ApplicationController
  LOTTERY_INTERVAL_SEC = ENV['DISPATCH_WINDOW_SECOND']&.to_i || 3

  def create
    id = SecureRandom.uuid

    order = {
      id: id,
      driver_id: nil,
      user_id: request.uuid,
      status: :pending
    }

    redis = RedisHelper.create_new_client
    redis.set("order:#{id}", order.to_json)
    redis.publish("order:#{id}:request", 'start_lottery')
    redis.set("order:#{id}:lottery_end_time", lottery_end_time)
    redis.close

    render json: { order: order }
  end

  private

  def lottery_end_time
    ((Time.current.to_f + LOTTERY_INTERVAL_SEC) * 1000).to_i # store with millisecond, as the timeframe is small therefore milliseconds should count
  end
end

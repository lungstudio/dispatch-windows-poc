# frozen_string_literal: true

class OrderRequestLotteryWorker
  include Sidekiq::Worker
  LOTTERY_INTERVAL_SEC = 3

  def perform(order_id, driver_id)
    Rails.logger.info("OrderRequestLotteryWorker.perform - START, order_id: #{order_id}, driver_id: #{driver_id}")

    redis = Redis.new
    lottery_end_time_key = "order:#{order_id}:lottery_end_time"
    channel_name = "order:#{order_id}:request"

    lottery_end_time = ((Time.current.to_f + LOTTERY_INTERVAL_SEC) * 1000).to_i # store with millisecond, as the timeframe is small therefore milliseconds should count
    redis.setex(lottery_end_time_key, 5.second.to_i, lottery_end_time)
    Rails.logger.info("OrderRequestLotteryWorker.perform - setex, key: #{lottery_end_time_key}, value: #{lottery_end_time}")

    drivers = [driver_id]
    start_time = Time.current
    begin
      redis.subscribe_with_timeout(LOTTERY_INTERVAL_SEC, channel_name) do |on|
        on.message do |_, message|
          drivers.push(JSON.parse(message)['driver_id'])
        end
      end
    rescue Redis::TimeoutError
      # this is expected, do nothing
    end
    Rails.logger.info("OrderRequestLotteryWorker.perform - subscribe time: #{(Time.current - start_time).to_f}s")

    Rails.logger.info("OrderRequestLotteryWorker.perform - drivers participated: #{drivers.as_json}")

    winner_id = OrderRequestLotteryService.draw(drivers)

    Rails.logger.info("OrderRequestLotteryWorker.perform - winner: #{winner_id}")

    redis.publish(channel_name, { winner_id: winner_id }.to_json)
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  ensure
    Rails.logger.info('OrderRequestLotteryWorker.perform - END')
  end
end

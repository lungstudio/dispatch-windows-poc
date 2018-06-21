# frozen_string_literal: true

class OrderRequestLotteryWorker
  include Sidekiq::Worker
  LOTTERY_INTERVAL_SEC = 10

  def perform(order_id, driver_id)
    Rails.logger.info("OrderRequestLotteryWorker.perform - START, order_id: #{order_id}, driver_id: #{driver_id}")

    redis = Redis.new
    lottery_end_time_key = "order:#{order_id}:lottery_end_time"
    channel_name = "order:#{order_id}:request"

    # set lottery end time
    lottery_end_time = ((Time.current.to_f + LOTTERY_INTERVAL_SEC) * 1000).to_i # store with millisecond, as the timeframe is small therefore milliseconds should count
    redis.set(lottery_end_time_key, lottery_end_time)
    Rails.logger.info("OrderRequestLotteryWorker.perform - redis set, key: #{lottery_end_time_key}, value: #{lottery_end_time}")

    drivers = [driver_id]
    start_time = Time.current

    # subscribe to channel
    EM.run do
      em_hiredis = EM::Hiredis.connect

      # store to drivers list
      em_hiredis.pubsub.subscribe(channel_name) do |message|
        drivers.push(JSON.parse(message)['driver_id'])
      rescue JSON::ParserError => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end

      # add a timeout and handle the lottery logic
      EM.add_timer(LOTTERY_INTERVAL_SEC) do
        em_hiredis.pubsub.unsubscribe(channel_name)

        # lucky draw
        Rails.logger.info("OrderRequestLotteryWorker.perform - drivers participated: #{drivers.as_json}")
        winner_id = OrderRequestLotteryService.draw(drivers)
        Rails.logger.info("OrderRequestLotteryWorker.perform - winner: #{winner_id}")

        # publish winner
        em_hiredis.publish(channel_name, { winner_id: winner_id }.to_json)

        # end EM
        EM.stop_event_loop
      end
    end

    Rails.logger.info("OrderRequestLotteryWorker.perform - lottery time: #{(Time.current - start_time).to_f}s")
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  ensure
    Rails.logger.info('OrderRequestLotteryWorker.perform - END')
  end
end

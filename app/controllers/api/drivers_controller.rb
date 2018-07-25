# frozen_string_literal: true

class Api::DriversController < ApplicationController
  LOTTERY_TIMEOUT_SEC = (ENV['DISPATCH_WINDOW_SECOND']&.to_i || 3) + 5

  def pick
    Rails.logger.info("DriversController.pick - START, params: #{params.as_json}")
    redis = RedisHelper.create_new_client

    # order = Order.find_by(id: params[:order_id], status: 'pending')
    order = find_order(redis, params[:order_id])
    return render_pick_forbidden(:order_not_found) unless order
    return render_pick_forbidden(:order_picked) if order['status'] == 'picked'

    lottery_end_time_key = "order:#{order['id']}:lottery_end_time"
    order_request_channel_name = "order:#{order['id']}:request"
    driver_id = request.uuid

    # check lottery_end_time on redis
    lottery_end_time = redis.get(lottery_end_time_key)
    Rails.logger.info("DriversController.pick - lottery_end_time: #{lottery_end_time || 'nil'}")

    if (Time.current.to_f * 1000).to_i <= lottery_end_time.to_i
      redis.publish(order_request_channel_name, { driver_id: driver_id }.to_json)
    else
      # lottery has ended, try picking with first-come-first-served basis
      return render_pick_forbidden(:dispatch_window_ended)
    end

    # subscribe to channel
    winner_id = nil
    no_of_drivers = nil
    start_time = Time.current
    begin
      redis.subscribe_with_timeout(LOTTERY_TIMEOUT_SEC, order_request_channel_name) do |on|
        # decode the message, check if the message is winner_id
        on.message do |_, message|
          m = JSON.parse(message)

          if m&.key?('winner_id')
            winner_id = m['winner_id']

            no_of_drivers = m['no_of_drivers'] if m&.key?('no_of_drivers')

            redis.unsubscribe
          end

        rescue JSON::ParserError => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    rescue Redis::TimeoutError
      Rails.logger.info("DriversController.pick - lottery timeout, driver id: #{driver_id}")
      return render_pick_forbidden(:lottery_timeout)
    end
    Rails.logger.info("DriversController.pick - subscribe time: #{(Time.current - start_time).to_f}s")

    # check if I am the winner?
    if winner_id == driver_id
      order['status'] = 'picked'
      order['driver_id'] = driver_id
      redis.set("order:#{order['id']}", order.to_json)
      return render json: { order: order, no_of_drivers: no_of_drivers }, status: :ok
    else
      render_pick_forbidden(:you_loser)
    end
  ensure
    Rails.logger.info('DriversController.pick- END')
    redis.close
  end

  private

  def find_order(redis, order_id)
    order_raw = redis.get("order:#{order_id}")
    JSON.parse(order_raw) if order_raw
  end
end

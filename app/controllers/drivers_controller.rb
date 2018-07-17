# frozen_string_literal: true

class DriversController < ApplicationController
  LOTTERY_TIMEOUT_SEC = (ENV['DISPATCH_WINDOW_SECOND']&.to_i || 10) + 5
  before_action :set_driver, only: %i[show edit update destroy]

  # GET /drivers
  # GET /drivers.json
  def index
    @drivers = Driver.all
  end

  # GET /drivers/1
  # GET /drivers/1.json
  def show; end

  # GET /drivers/new
  def new
    @driver = Driver.new
  end

  # GET /drivers/1/edit
  def edit; end

  # POST /drivers
  # POST /drivers.json
  def create
    @driver = Driver.new(driver_params)

    respond_to do |format|
      if @driver.save
        format.html { redirect_to @driver, notice: 'Driver was successfully created.' }
        format.json { render :show, status: :created, location: @driver }
      else
        format.html { render :new }
        format.json { render json: @driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /drivers/1
  # PATCH/PUT /drivers/1.json
  def update
    respond_to do |format|
      if @driver.update(driver_params)
        format.html { redirect_to @driver, notice: 'Driver was successfully updated.' }
        format.json { render :show, status: :ok, location: @driver }
      else
        format.html { render :edit }
        format.json { render json: @driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /drivers/1
  # DELETE /drivers/1.json
  def destroy
    @driver.destroy
    respond_to do |format|
      format.html { redirect_to drivers_url, notice: 'Driver was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def pick
    Rails.logger.info("DriversController.pick - START, params: #{params.as_json}")

    redis = NEW_REDIS_CLIENT

    order = Order.find_by(id: params[:order_id], status: 'pending')
    return render_forbidden(:order_not_found) unless order

    lottery_end_time_key = "order:#{order.id}:lottery_end_time"
    order_request_channel_name = "order:#{order.id}:request"
    driver_id = params[:id]

    # check lottery_end_time on redis
    lottery_end_time = redis.get(lottery_end_time_key)
    Rails.logger.info("DriversController.pick - lottery_end_time: #{lottery_end_time || 'nil'}")

    if (Time.current.to_f * 1000).to_i <= lottery_end_time.to_i
      redis.publish(order_request_channel_name, { driver_id: driver_id }.to_json)
    else
      # lottery has ended, try picking with first-come-first-served basis
      return pick_order(order, driver_id)
    end

    # subscribe to channel
    winner_id = nil
    start_time = Time.current
    begin
      redis.subscribe_with_timeout(LOTTERY_TIMEOUT_SEC, order_request_channel_name) do |on|
        # decode the message, check if the message is winner_id
        on.message do |_, message|
          m = JSON.parse(message)
          if m&.key?('winner_id')
            winner_id = m['winner_id']
            redis.unsubscribe
          end
        rescue JSON::ParserError => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    rescue Redis::TimeoutError
      Rails.logger.info("DriversController.pick - lottery timeout, driver id: #{driver_id}")
      return render_forbidden(:lottery_timeout)
    end
    Rails.logger.info("DriversController.pick - subscribe time: #{(Time.current - start_time).to_f}s")

    # check if I am the winner?
    if winner_id == driver_id
      return pick_order(order, driver_id)
    else
      render_forbidden(:you_loser)
    end
  ensure
    Rails.logger.info('DriversController.pick- END')
  end

  private

  def pick_order(order, driver_id)
    order.with_lock do
      order.send('pick')
      order.update!(driver_id: driver_id)
    end
    render json: { order: order }, status: :ok
  rescue AASM::InvalidTransition
    render_forbidden(:order_has_been_picked)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_driver
    @driver = Driver.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def driver_params
    params.require(:driver).permit(:name)
  end

  def render_forbidden(err_key)
    render json: { error: 'you are not allowed to pick this order', error_key: err_key }, status: :forbidden
  end
end

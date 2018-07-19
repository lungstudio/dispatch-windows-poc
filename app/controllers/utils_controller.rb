# frozen_string_literal: true

class UtilsController < ApplicationController
  def reset_all
    Order.delete_all
    User.delete_all
    Driver.delete_all
  end

  def reset_for_load_test
    reset_all
    user_count = params[:user_count]
    driver_count = params[:driver_count]

    if user_count
      users = []
      user_count.times { |i| users.push(id: i + 1, name: "Load Test User #{i + 1}") }
      User.create(users)
    end

    if driver_count
      drivers = []
      driver_count.times { |i| drivers.push(id: i + 1, name: "Load Test Driver #{i + 1}") }
      Driver.create(drivers)
    end
  end
end

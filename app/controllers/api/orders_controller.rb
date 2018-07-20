# frozen_string_literal: true

class Api::OrdersController < ApplicationController
  # get all order ids
  def index
    orders = Order.where(status: 'pending')&.pluck(:id) || []
    render json: orders
  end

  def create
    o = Order.create!(user_id: request.uuid)
    render json: { order: o }
  end
end

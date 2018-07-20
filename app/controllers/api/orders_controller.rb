# frozen_string_literal: true

class Api::OrdersController < ApplicationController
  # get all pending order ids
  def index
    orders = Order.where(status: 'pending')&.pluck(:id) || []
    render json: orders
  end

  def create
    o = Order.create!(user_id: request.uuid)
    render json: { order: o }
  end

  def delete_all
    Order.delete_all
  end
end

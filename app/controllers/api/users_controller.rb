# frozen_string_literal: true

class Api::UsersController < ApplicationController
  def create
    u = User.create!(name: params[:name])
    render json: { user: u }
  end

  def create_order
    o = Order.create!(user_id: params[:user_id])
    render json: { order: o }
  end
end

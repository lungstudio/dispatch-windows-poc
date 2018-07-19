# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery

  def render_pick_forbidden(err_key)
    render json: { error: 'you are not allowed to pick this order', error_key: err_key }, status: :forbidden
  end
end

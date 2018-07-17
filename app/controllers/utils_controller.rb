# frozen_string_literal: true

class UtilsController < ApplicationController
  def reset_all
    Order.delete_all
    User.delete_all
    Driver.delete_all
  end
end

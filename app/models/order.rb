# frozen_string_literal: true

class Order < ApplicationRecord
  include AASM

  after_create :trigger_lottery_job

  aasm column: 'status' do
    state :pending, initial: true
    state :picked

    event :pick do
      transitions from: :pending, to: :picked, success: :assgin_driver
    end
  end

  private

  def trigger_lottery_job
    OrderRequestLotteryWorker.perform_async(id)
  end
end

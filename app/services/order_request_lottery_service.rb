# frozen_string_literal: true

module OrderRequestLotteryService
  class << self
    def draw(driver_list)
      driver_list.sample
    end
  end
end

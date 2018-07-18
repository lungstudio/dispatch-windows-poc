# frozen_string_literal: true

module DispatchWindowWinnerPickerService
  class << self
    def pick(driver_list)
      driver_list.sample
    end
  end
end

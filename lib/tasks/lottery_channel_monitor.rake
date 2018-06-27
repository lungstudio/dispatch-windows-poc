# frozen_string_literal: true

namespace :lottery_channel_monitor do
  task run: :environment do
    # Trap ^C
    Signal.trap('INT') do
      puts 'exiting with signal INT'
      exit
    end

    # Trap `Kill`
    Signal.trap('TERM') do
      puts 'exiting with signal TERM'
      exit
    end

    worker = OrderRequestLotteryWorker.new
    worker.perform
  end
end

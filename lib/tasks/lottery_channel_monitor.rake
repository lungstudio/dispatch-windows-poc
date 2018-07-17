# frozen_string_literal: true

namespace :lottery_channel_monitor do
  task run: :environment do
    Rails.logger.info('lottery_channel_monitor.rake - before signal trap')
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

    Rails.logger.info('lottery_channel_monitor.rake - Perform')
    worker = OrderRequestLotteryWorker.new
    worker.perform
  end
end

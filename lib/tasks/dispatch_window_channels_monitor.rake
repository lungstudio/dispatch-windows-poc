# frozen_string_literal: true

namespace :dispatch_window_channels_monitor do
  task run: :environment do
    puts 'hehehehehehahahahaha'
    Rails.logger.info('dispatch_window_channels_monitor.rake - before signal trap')
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

    Rails.logger.info('dispatch_window_channels_monitor.rake - Perform')
    worker = DispatchWindowMonitorWorker.new
    worker.perform
  end
end

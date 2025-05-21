class SampleActiveJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # This job will be processed by Sidekiq
    puts "Running SampleActiveJob with arguments: #{args.inspect}"
    # This will show up in your Sidekiq logs
  end
end 
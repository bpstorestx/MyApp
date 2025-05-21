class SampleJob
  include Sidekiq::Job

  def perform(*args)
    # Just a simple job for testing
    puts "Running sample job with arguments: #{args.inspect}"
    # This will show up in your Sidekiq logs
  end
end 
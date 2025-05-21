puts "==== Sidekiq Queue Repair Tool ===="

require_relative 'config/environment'
require 'sidekiq/api'

puts "Rails environment: #{Rails.env}"
puts "Redis URL: #{ENV['REDIS_URL'] || 'Using default: redis://localhost:6379/0'}"

# Check if Redis is accessible
begin
  redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
  redis_response = redis.ping
  puts "Redis connection: #{redis_response == 'PONG' ? 'SUCCESS' : 'FAILED'}"
rescue => e
  puts "Redis connection error: #{e.message}"
end

# Check if there are jobs in the queue
begin
  queue = Sidekiq::Queue.new('default')
  dead = Sidekiq::DeadSet.new
  retry_set = Sidekiq::RetrySet.new
  
  puts "\nQueue Status:"
  puts "- Default queue size: #{queue.size}"
  puts "- Dead jobs: #{dead.size}"
  puts "- Retrying jobs: #{retry_set.size}"
  
  if queue.size > 0
    puts "\nJobs in queue:"
    queue.each do |job|
      puts "- JID: #{job.jid}, Class: #{job.klass}, Args: #{job.args.inspect}, Queue: #{job.queue}, Created: #{Time.at(job.enqueued_at)}"
    end
  end
  
  if retry_set.size > 0
    puts "\nRetrying jobs:"
    retry_set.each do |job|
      puts "- JID: #{job.jid}, Class: #{job.klass}, Error: #{job['error_message']}, Retry Count: #{job['retry_count']}"
    end
  end
  
  if dead.size > 0
    puts "\nDead jobs:"
    dead.each do |job|
      puts "- JID: #{job.jid}, Class: #{job.klass}, Error: #{job['error_message']}"
    end
  end
  
  # Look for worker processes
  puts "\nWorker Processes:"
  workers = Sidekiq::Workers.new
  if workers.size > 0
    workers.each do |process_id, thread_id, work|
      puts "- Process: #{process_id}, Thread: #{thread_id}, Job: #{work['payload']['class']}"
    end
  else
    puts "- No active workers found! This is likely the problem."
  end

  # Check if FloorplanWorker is defined
  begin
    puts "\nFloorplanWorker class loaded: #{defined?(FloorplanWorker) == 'constant' ? 'YES' : 'NO'}"
  rescue => e
    puts "Error checking FloorplanWorker: #{e.message}"
  end
  
  # Fix: Try to clear the queue and reset the worker process
  if ARGV.include?('--fix')
    puts "\nAttempting to fix issues..."
    
    # Clear any stuck jobs
    queue.each do |job|
      if job.klass == 'FloorplanWorker'
        puts "Removing stuck job: #{job.jid}"
        job.delete
      end
    end
    
    # Reset any broken floorplans
    if defined?(Floorplan)
      stuck_floorplans = Floorplan.where(status: ['pending', 'processing'])
      if stuck_floorplans.any?
        puts "Resetting #{stuck_floorplans.count} stuck floorplans..."
        stuck_floorplans.update_all(status: 'failed')
      end
    end
    
    puts "Fix completed. Please restart your Sidekiq worker process."
  else
    puts "\nTo fix stuck jobs, run this script with --fix argument"
  end
  
rescue => e
  puts "Error checking queue: #{e.message}"
  puts e.backtrace[0..5]
end

puts "\n==== Action Required ===="
puts "1. Make sure Redis server is running"
puts "2. Make sure Sidekiq is running in a separate terminal with: bundle exec sidekiq -e development"
puts "3. Check worker log at log/sidekiq.log for errors"
puts "4. If needed, run this script with --fix to clear stuck jobs" 
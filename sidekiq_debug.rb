puts "==== Sidekiq Development Debug ===="
puts "RAILS_ENV: #{ENV['RAILS_ENV'] || 'not set'}"
puts "REDIS_URL: #{ENV['REDIS_URL'] || 'not set'}"

# Try to load Rails environment
require_relative 'config/environment'
puts "Rails.env: #{Rails.env}"

# Check Redis connection
begin
  require 'redis'
  redis = Redis.new(url: ENV['REDIS_URL']) 
  puts "Redis connection test: #{redis.ping}" # Should print "PONG"
  puts "Redis info: #{redis.info.slice('redis_version', 'connected_clients').inspect}"
rescue => e
  puts "Redis connection error: #{e.message}"
end

# Check Sidekiq configuration
begin
  require 'sidekiq'
  puts "Sidekiq version: #{Sidekiq::VERSION}"
  puts "Sidekiq client config: #{Sidekiq.default_configuration.client}"
  puts "Sidekiq server config: #{Sidekiq.default_configuration.server}"
rescue => e
  puts "Sidekiq error: #{e.message}"
end

puts "==== Debug Complete ====" 
require 'redis'

# The Redis URL from Heroku (replace with your actual URL if needed)
redis_url = ENV['REDIS_URL'] || 'rediss://p5d8f287a9e023c96ba7e7d2ae233fcbbf55b6e022aa3ddb43e15a56e97e93ff2@ec2-3-82-214-32.compute-1.amazonaws.com:16470'

puts "Connecting to Redis at: #{redis_url}"

# Configure Redis with SSL if using rediss://
redis_options = { url: redis_url }

if redis_url.start_with?('rediss://')
  puts "Detected SSL Redis connection, enabling SSL options"
  require 'openssl'
  redis_options[:ssl] = true
  redis_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
end

puts "Redis options: #{redis_options.inspect}"

# Create Redis client and test connection
begin
  redis = Redis.new(redis_options)
  result = redis.ping
  puts "Successfully connected to Redis! Response: #{result}"
rescue => e
  puts "Error connecting to Redis: #{e.message}"
  puts e.backtrace.join("\n")
end 
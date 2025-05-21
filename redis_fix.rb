#!/usr/bin/env ruby
# This script can be run in the Heroku console to fix Redis configuration issues
# Just copy and paste the entire content into the Heroku console

begin
  puts "Starting Redis configuration fix..."
  
  # Get the Redis URL
  redis_url = ENV['REDIS_URL']
  puts "Current Redis URL: #{redis_url ? redis_url.gsub(/:[^:@]+@/, ':***@') : 'not set'}"
  
  # Override Redis configuration for SSL connections
  if defined?(Redis) && redis_url && redis_url.start_with?('rediss://')
    puts "Detected Redis SSL URL, applying SSL configuration..."
    
    # Apply SSL patch to Redis::Client
    Redis::Client.class_eval do
      def connect_with_ssl
        if @options[:url].to_s.start_with?('rediss://')
          @options[:ssl] = true
          @options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
          puts "Applied SSL options to Redis connection"
        end
        connect_without_ssl
      end
      
      # Only apply if not already patched
      unless method_defined?(:connect_without_ssl)
        alias_method :connect_without_ssl, :connect
        alias_method :connect, :connect_with_ssl
        puts "Patched Redis::Client#connect method"
      else
        puts "Redis::Client already patched"
      end
    end
    
    # Test the connection
    puts "Testing Redis connection..."
    redis = Redis.new
    result = redis.ping
    puts "Redis ping successful: #{result}"
    
    # Fix Sidekiq configuration if present
    if defined?(Sidekiq)
      puts "Applying SSL configuration to Sidekiq..."
      
      redis_conn = { url: redis_url, ssl: true, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
      
      # Update both client and server
      Sidekiq.configure_client do |config|
        config.redis = redis_conn
      end
      
      Sidekiq.configure_server do |config|
        config.redis = redis_conn
      end
      
      puts "Sidekiq Redis configuration updated"
    else
      puts "Sidekiq not defined in this context"
    end
    
    puts "Redis configuration fix completed successfully"
  else
    puts "No Redis SSL URL detected or Redis not defined"
  end
rescue => e
  puts "Error applying Redis configuration fix: #{e.message}"
  puts e.backtrace.join("\n")
end 
require 'sidekiq'
require 'sidekiq/web'
require 'openssl'

# Log Redis URL for debugging
Rails.logger.info("REDIS CONFIG: REDIS_URL=#{ENV['REDIS_URL'] || 'not set'}")

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  redis_config = { url: ENV['REDIS_URL'] }
  
  # Add SSL options if using rediss:// (Redis over SSL)
  if redis_config[:url] && redis_config[:url].start_with?('rediss://')
    Rails.logger.info("Redis SSL configuration enabled for URL: #{redis_config[:url].gsub(/:[^:]*@/, ':***@')}")
    redis_config[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    Rails.logger.info("Redis SSL verification disabled")
  end
  
  config.redis = redis_config
end

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  redis_config = { 
    url: ENV['REDIS_URL'],
    size: 10  # Increasing from the default to meet Sidekiq's requirements
  }
  
  # Add SSL options if using rediss:// (Redis over SSL)
  if redis_config[:url] && redis_config[:url].start_with?('rediss://')
    Rails.logger.info("Redis SSL configuration enabled for URL: #{redis_config[:url].gsub(/:[^:]*@/, ':***@')}")
    redis_config[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    Rails.logger.info("Redis SSL verification disabled")
  end
  
  config.redis = redis_config
end

# No authentication for Sidekiq Web UI for easier access

# Only configure Sidekiq Web UI if required
begin
  require 'sidekiq/web'
rescue LoadError
  # Sidekiq Web UI isn't available
end 
require 'sidekiq'
require 'sidekiq/web'
require 'openssl'

# Log Redis URL for debugging
Rails.logger.info("REDIS CONFIG: REDIS_URL=#{ENV['REDIS_URL'] || 'not set'}")

# Default Redis connection for development
redis_config = if Rails.env.development?
  { url: 'redis://localhost:6379/0' }
else
  { url: ENV['REDIS_URL'] }
end

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  # Add SSL options if using rediss:// (Redis over SSL) in production
  if redis_config[:url] && redis_config[:url].start_with?('rediss://')
    Rails.logger.info("Redis SSL configuration enabled for URL: #{redis_config[:url].gsub(/:[^:]*@/, ':***@')}")
    redis_config[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    Rails.logger.info("Redis SSL verification disabled")
  end
  
  config.redis = redis_config
end

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  server_redis_config = redis_config.dup
  
  # Increase connection pool size for server
  if Rails.env.production?
    server_redis_config[:size] = 10  # Larger pool for production
  else
    server_redis_config[:size] = 5   # Smaller pool for development
  end
  
  # Add SSL options if using rediss:// (Redis over SSL) in production
  if server_redis_config[:url] && server_redis_config[:url].start_with?('rediss://')
    Rails.logger.info("Redis SSL configuration enabled for URL: #{server_redis_config[:url].gsub(/:[^:]*@/, ':***@')}")
    server_redis_config[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    Rails.logger.info("Redis SSL verification disabled")
  end
  
  config.redis = server_redis_config
end

# No authentication for Sidekiq Web UI for easier access

# Only configure Sidekiq Web UI if required
begin
  require 'sidekiq/web'
rescue LoadError
  # Sidekiq Web UI isn't available
end 
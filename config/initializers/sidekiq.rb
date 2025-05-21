require 'sidekiq'

# Log Redis URL for debugging
Rails.logger.info("REDIS CONFIG: REDIS_URL=#{ENV['REDIS_URL'] || 'not set'}")

# Configure Redis with explicit options
redis_conn_opts = {
  url: ENV['REDIS_URL'],
  network_timeout: 15,  # Increased timeout
  socket_timeout: 15,   # Increased socket timeout
  reconnect_attempts: 5,  # Allow multiple reconnect attempts
  size: 1  # Reduce connection pool size to minimize issues
}

Sidekiq.configure_server do |config|
  config.redis = redis_conn_opts
end

Sidekiq.configure_client do |config|
  config.redis = redis_conn_opts
end

# Only configure Sidekiq Web UI if required
begin
  require 'sidekiq/web'
rescue LoadError
  # Sidekiq Web UI isn't available
end 
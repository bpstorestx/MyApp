require 'sidekiq'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'), timeout: 5 }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'), timeout: 5 }
end

# Only configure Sidekiq Web UI if required
begin
  require 'sidekiq/web'
rescue LoadError
  # Sidekiq Web UI isn't available
end 
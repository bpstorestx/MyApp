require 'redis'

# Configure Redis for SSL if using rediss://
if ENV['REDIS_URL'].to_s.start_with?('rediss://')
  # Custom Redis connection factory with SSL
  Redis::Client.class_eval do
    # Override the default connection
    def connect_with_ssl
      if @options[:url].to_s.start_with?('rediss://')
        # Add SSL configuration
        @options[:ssl] = true
        @options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        
        # Log the connection attempt
        Rails.logger.info("Connecting to Redis with SSL: #{@options[:url]}")
      end
      
      # Call the original method
      connect_without_ssl
    end
    
    # Setup the method chain
    alias_method :connect_without_ssl, :connect
    alias_method :connect, :connect_with_ssl
  end
  
  Rails.logger.info("Redis SSL configuration enabled for URL: #{ENV['REDIS_URL'].to_s.gsub(/:[^:@]+@/, ':***@')}")
end 
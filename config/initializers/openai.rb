require "openai"

# Configure the OpenAI client with API key from environment
# Falls back to credentials if ENV var is not set
OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY") { Rails.application.credentials.dig(:openai, :api_key) }
  
  # Optional: Configure additional options
  # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", nil)
  # config.request_timeout = 120 # seconds
end 
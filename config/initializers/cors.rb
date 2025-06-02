# Be sure to restart your server when you modify this file.

# Require the rack-cors gem
require 'rack/cors'

# Configure CORS for ActiveStorage
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/rails/active_storage/blobs/*',
      headers: :any,
      methods: [:get, :options],
      credentials: false
    resource '/rails/active_storage/representations/*',
      headers: :any,
      methods: [:get, :options],
      credentials: false
    resource '/rails/active_storage/disk/*',
      headers: :any,
      methods: [:get, :options],
      credentials: false
  end
end 
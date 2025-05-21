#!/usr/bin/env ruby
require 'fileutils'

APP_ROOT = File.expand_path('..', __dir__)
FileUtils.chdir(APP_ROOT) do
  puts "Starting Sidekiq in development mode..."
  
  # Set environment variables if needed
  ENV['RAILS_ENV'] = 'development'
  
  begin
    exec "bundle exec sidekiq -e development -C config/sidekiq.yml"
  rescue => e
    puts "Failed to start Sidekiq: #{e.message}"
    exit 1
  end
end 
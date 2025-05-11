#!/usr/bin/env ruby
# Tests the Heroku API key configuration by making a simple API call

require 'net/http'
require 'uri'
require 'json'

puts "===== Heroku OpenAI API Key Test ====="

# Get API key from Heroku config
puts "Fetching API key from Heroku config..."
heroku_config = `heroku config`
api_key = nil

if heroku_config.include?("OPENAI_API_KEY")
  # Extract the API key
  config_lines = heroku_config.split("\n")
  api_key_line = config_lines.find { |line| line.include?("OPENAI_API_KEY") }
  
  if api_key_line
    key_parts = api_key_line.split(":")
    if key_parts.length > 1
      api_key = key_parts[1].strip
      puts "✅ Found API key: #{api_key[0..5]}...#{api_key[-4..-1]}"
      puts "Key length: #{api_key.length} characters"
    end
  end
else
  puts "❌ OPENAI_API_KEY not found in Heroku config"
  exit 1
end

# Exit if no API key found
unless api_key
  puts "❌ Could not extract API key from Heroku config"
  exit 1
end

# Make simple API request to OpenAI
puts "\nTesting API key with a simple OpenAI API call..."
uri = URI.parse("https://api.openai.com/v1/models")
request = Net::HTTP::Get.new(uri)
request["Authorization"] = "Bearer #{api_key}"

begin
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  case response.code.to_i
  when 200
    puts "✅ API key works! Successfully retrieved models list."
    
    # Parse response to get model list
    models = JSON.parse(response.body)
    if models["data"] && models["data"].is_a?(Array)
      puts "\nAvailable models:"
      
      # Check for gpt-image-1 specifically
      if models["data"].any? { |m| m["id"] == "gpt-image-1" }
        puts "✅ gpt-image-1 model is available with this API key"
      else
        puts "❌ gpt-image-1 model is NOT available with this API key"
      end
      
      # Show a few models
      models["data"].first(5).each do |model|
        puts "- #{model["id"]}"
      end
      puts "... and #{models["data"].size - 5} more"
    end
  when 401
    puts "❌ API key is invalid. Authentication failed."
    puts "Response: #{response.body}"
  when 429
    puts "❌ Rate limited. Too many requests."
    puts "Response: #{response.body}"
  else
    puts "❌ Unexpected response (#{response.code}):"
    puts "Response: #{response.body}"
  end
rescue => e
  puts "❌ Error during API request: #{e.message}"
end

puts "\n===== API Key Test Complete =====" 
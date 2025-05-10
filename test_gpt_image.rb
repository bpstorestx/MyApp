#!/usr/bin/env ruby
# Test script for OpenAI's gpt-image-1 model

require 'rubygems'
require 'bundler/setup'
require 'openai'
require 'dotenv/load'

puts "Testing OpenAI gpt-image-1 model..."

# Check API key
api_key = ENV['OPENAI_API_KEY']
if api_key.nil? || api_key.empty?
  puts "❌ ERROR: No API key found in environment variables"
  exit 1
end

puts "✅ API Key found: #{api_key[0..5]}...#{api_key[-4..-1]}"
puts "API Key length: #{api_key.length} characters"

# Check for test image
test_image_path = File.join(Dir.pwd, 'Test_Lawn.webp')
unless File.exist?(test_image_path)
  puts "❌ ERROR: Test image not found at: #{test_image_path}"
  exit 1
end

puts "✅ Test image found: #{test_image_path}"

# Initialize client
puts "\nInitializing OpenAI client..."
client = OpenAI::Client.new(access_token: api_key)

# Create a prompt
prompt = "Create an enhanced landscape design for this residential property with beautiful gardens, pathways, and well-maintained lawn."

# Try gpt-image-1 model with an image input
puts "\nTesting gpt-image-1 model with image input..."

begin
  puts "Sending request to OpenAI API..."
  response = client.images.generate(
    parameters: {
      model: "gpt-image-1",
      prompt: prompt,
      image: File.open(test_image_path, "rb"),
      n: 1
    }
  )

  if response["data"] && response["data"][0] && response["data"][0]["url"]
    puts "✅ Success! Image URL:"
    puts response["data"][0]["url"]
  else
    puts "❌ Unexpected response format:"
    puts response.inspect
  end
rescue => e
  puts "❌ ERROR: #{e.message}"
  puts "\nStack trace:"
  puts e.backtrace.first(5)
end

puts "\n=== Test Complete ===" 
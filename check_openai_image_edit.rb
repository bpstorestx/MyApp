#!/usr/bin/env ruby
# Script to specifically test the OpenAI API for image editing with gpt-image-1

require 'rubygems'
require 'bundler/setup'
require 'openai'
require 'base64'
require 'tempfile'

puts "===== OpenAI GPT-Image-1 Image Editing Test ====="
puts "This script tests the OpenAI API specifically for image editing functionality"
puts "Using gpt-image-1 model to edit an image"

# Check for API key in environment
api_key = ENV['OPENAI_API_KEY']
if api_key.nil? || api_key.empty?
  puts "❌ ERROR: No API key found in environment variables"
  exit 1
end

puts "✅ API Key found: #{api_key[0..5]}...#{api_key[-4..-1]}"
puts "API Key length: #{api_key.length} characters"

# Initialize OpenAI client
puts "\nInitializing OpenAI client..."
client = OpenAI::Client.new(access_token: api_key)
puts "Client initialized successfully"

# Test image path 
test_image_path = File.join(Dir.pwd, 'Test_Lawn.webp')
unless File.exist?(test_image_path)
  puts "❌ Test image not found at: #{test_image_path}"
  puts "Please place the 'Test_Lawn.webp' file in the root of your project."
  exit 1
end

puts "✅ Test image found at: #{test_image_path}"

# Create a prompt for landscape enhancement
prompt = <<~PROMPT
  Transform this property photo with enhanced landscaping.
  Add beautiful garden beds with colorful flowers, decorative stone pathways, and a well-maintained lawn.
  Make it look like a professional landscaping job was completed.
PROMPT

puts "Using prompt: #{prompt}"

# Try to edit the image using the gpt-image-1 model
puts "\nPreparing to call OpenAI's gpt-image-1 API for image editing..."

begin
  # Read image binary data
  puts "Reading image file..."
  image_data = File.binread(test_image_path)
  puts "Image read successfully (#{image_data.bytesize} bytes)"
  
  # Convert to base64
  puts "Converting image to base64..."
  base64_image = Base64.strict_encode64(image_data)
  puts "Base64 conversion complete (#{base64_image.bytesize} bytes)"
  
  # Make API call
  puts "\nMaking API call to OpenAI (gpt-image-1)..."
  puts "Start time: #{Time.now}"
  
  response = client.images.edit(
    parameters: {
      model: "gpt-image-1",
      image: base64_image,
      prompt: prompt,
      n: 1
    }
  )
  
  puts "End time: #{Time.now}"
  
  # Process response
  if response["data"] && response["data"][0] && response["data"][0]["url"]
    puts "\n✅ SUCCESS! Enhanced image URL:"
    puts response["data"][0]["url"]
  else
    puts "\n⚠️ Response received but no image URL found."
    puts "Full response:"
    require 'json'
    puts JSON.pretty_generate(response)
  end
  
rescue => e
  puts "❌ ERROR during API call: #{e.message}"
  puts "Error class: #{e.class}"
  
  if e.respond_to?(:response) && e.response
    puts "\nResponse details:"
    puts "Status: #{e.response[:status]}"
    puts "Headers: #{e.response[:headers]}"
    
    body = e.response[:body]
    if body
      if body.is_a?(String)
        puts "Body (raw): #{body}"
        begin
          require 'json'
          parsed = JSON.parse(body)
          puts "Body (parsed):"
          puts JSON.pretty_generate(parsed)
        rescue
          # Not JSON
        end
      else
        puts "Body: #{body.inspect}"
      end
    end
  end
  
  puts "\nStack trace:"
  puts e.backtrace
end

puts "\n===== Test completed ===== 
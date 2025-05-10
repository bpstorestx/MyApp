#!/usr/bin/env ruby
# Debug script to test the LandscapePromptBuilder service with gpt-image-1

# Load the Rails environment
require File.expand_path('./config/environment', __dir__)
require 'tempfile'

puts "===== Landscape Enhancement Debug Tool ====="
puts "Using gpt-image-1 to edit the user's uploaded image"

# Check API key
api_key = ENV['OPENAI_API_KEY']
if api_key.nil? || api_key.empty?
  puts "❌ ERROR: No API key found in environment variables"
  exit 1
end

puts "✅ API Key detected: #{api_key[0..5]}...#{api_key[-4..-1]}"

# Check if the test image exists
test_image_path = File.join(Rails.root, 'Test_Lawn.webp')
unless File.exist?(test_image_path)
  puts "❌ Test image not found at: #{test_image_path}"
  puts "Please place the 'Test_Lawn.webp' file in the root of your project."
  exit 1
end

puts "✅ Test image located at: #{test_image_path}"

# Find an existing photo or create a new one
photo = if Photo.exists?
  test_photo = Photo.last
  puts "Using existing photo (ID: #{test_photo.id})"
  
  # Check if the photo has an image attached
  unless test_photo.original_image.attached?
    puts "Attaching test image to the photo..."
    test_photo.original_image.attach(io: File.open(test_image_path), filename: 'Test_Lawn.webp', content_type: 'image/webp')
    test_photo.save!
  end
  
  test_photo
else
  puts "Creating a new photo with the test image..."
  new_photo = Photo.new(status: "pending")
  new_photo.original_image.attach(io: File.open(test_image_path), filename: 'Test_Lawn.webp', content_type: 'image/webp')
  new_photo.save!
  new_photo
end

puts "\nRunning LandscapePromptBuilder with gpt-image-1..."
puts "This will edit the user's uploaded image (not generate from scratch)"
begin
  # Create a new service instance
  puts "Creating service..."
  service = LandscapePromptBuilder.new(photo)
  
  # Process the photo
  puts "Processing photo..."
  result = service.process
  
  puts "✅ Service completed successfully!"
  puts "Status: #{result.status}"
  
  # Display results
  if result.ai_image_url.include?("placehold.co")
    puts "\n⚠️ Notice: Used placeholder image (API call might have failed)"
    puts "Check Rails logs for detailed error information"
  else
    puts "\n🎉 Success! Enhanced landscape generated with gpt-image-1"
    puts "Enhanced image URL: #{result.ai_image_url}"
    puts "\nOriginal image vs Enhanced image:"
    puts "- Original: #{Rails.application.routes.url_helpers.rails_blob_url(photo.original_image) rescue 'Not available'}"
    puts "- Enhanced: #{result.ai_image_url}"
  end
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n===== Debug Complete =====" 
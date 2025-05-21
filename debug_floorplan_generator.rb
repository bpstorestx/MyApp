#!/usr/bin/env ruby

# Debug script for testing the FloorplanGenerator service
require_relative 'config/environment'
require 'logger'

# Set up a logger
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
Rails.logger = logger if defined?(Rails)

# Class for error testing
class FloorplanGeneratorWithError < FloorplanGenerator
  def generate
    raise StandardError, "Simulated error for testing"
  end
end

class MockFloorplan
  attr_accessor :status, :generated_image_url
  
  def initialize
    @status = "pending"
    @generated_image_url = nil
  end
  
  def original_image
    # Return the path to the test image
    File.open("2 Test Floorplan.jpg")
  end
  
  def update!(attributes)
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
    puts "Floorplan updated: #{attributes.inspect}"
    true
  end
  
  def to_s
    "MockFloorplan(status: #{@status}, image_url: #{@generated_image_url})"
  end
end

# Test with OpenAI API key
def test_with_openai
  puts "\n=== Testing FloorplanGenerator with OpenAI ==="
  
  # Use the actual API key from environment
  if ENV["OPENAI_API_KEY"].nil?
    puts "Error: OPENAI_API_KEY environment variable is not set"
    return
  end
  
  floorplan = MockFloorplan.new
  generator = FloorplanGenerator.new(floorplan)
  
  puts "Before generation: #{floorplan}"
  generator.generate
  puts "After generation: #{floorplan}"
end

# Test without OpenAI API key
def test_without_openai
  puts "\n=== Testing FloorplanGenerator without OpenAI ==="
  
  # Store the original API key
  original_key = ENV["OPENAI_API_KEY"]
  ENV["OPENAI_API_KEY"] = nil
  
  floorplan = MockFloorplan.new
  generator = FloorplanGenerator.new(floorplan)
  
  puts "Before generation: #{floorplan}"
  generator.generate
  puts "After generation: #{floorplan}"
  
  # Restore the original API key
  ENV["OPENAI_API_KEY"] = original_key
end

# Test with error simulation
def test_with_error
  puts "\n=== Testing FloorplanGenerator with error simulation ==="
  
  floorplan = MockFloorplan.new
  generator = FloorplanGeneratorWithError.new(floorplan)
  
  puts "Before generation: #{floorplan}"
  begin
    generator.generate
  rescue => e
    puts "Error caught: #{e.message}"
  end
  puts "After generation: #{floorplan}"
end

# Run all tests
puts "Starting FloorplanGenerator debug tests..."
test_without_openai
test_with_openai
test_with_error
puts "\nDebug tests completed." 
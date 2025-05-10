#!/usr/bin/env ruby
puts "API Key Check"
puts "============"
puts "API key present in ENV: #{ENV['OPENAI_API_KEY'].present?}"
if ENV['OPENAI_API_KEY'].present?
  puts "First 6 chars: #{ENV['OPENAI_API_KEY'][0..5]}"
  puts "Last 4 chars: #{ENV['OPENAI_API_KEY'][-4..-1]}"
  puts "Total length: #{ENV['OPENAI_API_KEY'].length}"
else
  puts "API key not found in environment"
end
puts "============" 
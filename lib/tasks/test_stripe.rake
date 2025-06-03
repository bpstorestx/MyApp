namespace :stripe do
  desc "Test Stripe configuration"
  task test: :environment do
    puts "Testing Stripe integration..."
    puts "Environment variables:"
    puts "STRIPE_SECRET_KEY: #{ENV['STRIPE_SECRET_KEY'].present? ? 'Set (' + ENV['STRIPE_SECRET_KEY'][0..10] + '...)' : 'NOT SET'}"
    puts "STRIPE_PUBLISHABLE_KEY: #{ENV['STRIPE_PUBLISHABLE_KEY'].present? ? 'Set (' + ENV['STRIPE_PUBLISHABLE_KEY'][0..10] + '...)' : 'NOT SET'}"
    
    if ENV['STRIPE_SECRET_KEY'].present?
      begin
        require 'stripe'
        Stripe.api_key = ENV['STRIPE_SECRET_KEY']
        # Test a simple Stripe API call
        Stripe::Account.retrieve
        puts "✅ Stripe API connection successful!"
      rescue Stripe::AuthenticationError => e
        puts "❌ Stripe authentication failed: #{e.message}"
      rescue => e
        puts "❌ Stripe error: #{e.message}"
      end
    else
      puts "❌ STRIPE_SECRET_KEY not found in environment"
    end
  end
end 
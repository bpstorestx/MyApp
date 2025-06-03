require 'stripe'

class SubscriptionsController < ApplicationController
  before_action :require_login, except: [:webhook]
  skip_before_action :verify_authenticity_token, only: [:webhook]
  
  def show
    # Redirect GET requests to /subscribe to the floorplan upload page
    # where users can see subscription options and upgrade
    redirect_to new_floorplan_path, notice: "Ready to upgrade? You'll find subscription options on this page!"
  end
  
  def create
    Rails.logger.info "=== STRIPE SUBSCRIPTION CREATE STARTED ==="
    Rails.logger.info "User: #{current_user.email}"
    Rails.logger.info "Stripe Secret Key present: #{ENV['STRIPE_SECRET_KEY'].present?}"
    
    # Check if Stripe is configured
    unless ENV['STRIPE_SECRET_KEY'].present?
      Rails.logger.error "Stripe secret key is missing!"
      flash[:alert] = "Stripe is not configured. Please contact support."
      redirect_to root_path
      return
    end
    
    Rails.logger.info "Stripe configuration OK, proceeding with subscription creation"
    
    # Ensure user has a Stripe customer ID
    current_user.create_stripe_customer! unless current_user.stripe_customer_id
    Rails.logger.info "Stripe customer ID: #{current_user.stripe_customer_id}"
    
    # Build line items based on configuration
    line_items = if Rails.application.config.stripe[:price_id].present?
      Rails.logger.info "Using pre-created price: #{Rails.application.config.stripe[:price_id]}"
      # Use pre-created price if available
      [{
        price: Rails.application.config.stripe[:price_id],
        quantity: 1,
      }]
    else
      Rails.logger.info "Using dynamic pricing with product: #{Rails.application.config.stripe[:product_id]}"
      # Create price dynamically using product ID
      [{
        price_data: {
          currency: 'usd',
          product: Rails.application.config.stripe[:product_id],
          recurring: {
            interval: 'month',
          },
          unit_amount: 900, # $9.00 in cents
        },
        quantity: 1,
      }]
    end
    
    Rails.logger.info "Creating Stripe checkout session..."
    
    # Create Stripe checkout session
    session = Stripe::Checkout::Session.create({
      customer: current_user.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: line_items,
      mode: 'subscription',
      success_url: root_url + '?subscription=success',
      cancel_url: root_url + '?subscription=canceled',
      client_reference_id: current_user.id.to_s
    })
    
    Rails.logger.info "Stripe session created successfully: #{session.id}"
    Rails.logger.info "Redirecting to: #{session.url}"
    
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    Rails.logger.error "Stripe error details: #{e.inspect}"
    flash[:alert] = "There was an error processing your request: #{e.message}"
    redirect_to root_path
  rescue => e
    Rails.logger.error "General error in subscription creation: #{e.message}"
    Rails.logger.error "Error details: #{e.inspect}"
    flash[:alert] = "An unexpected error occurred. Please try again."
    redirect_to root_path
  end
  
  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: 400
      return
    end
    
    case event['type']
    when 'checkout.session.completed'
      session = event['data']['object']
      handle_successful_payment(session)
    when 'invoice.payment_succeeded'
      invoice = event['data']['object']
      handle_successful_payment_renewal(invoice)
    when 'customer.subscription.deleted'
      subscription = event['data']['object']
      handle_subscription_cancellation(subscription)
    end
    
    render json: { message: 'success' }
  end
  
  private
  
  def handle_successful_payment(session)
    user = User.find(session['client_reference_id'])
    subscription_id = session['subscription']
    
    # Retrieve the subscription to get end date
    subscription = Stripe::Subscription.retrieve(subscription_id)
    end_date = Time.at(subscription.current_period_end)
    
    user.update!(
      stripe_subscription_id: subscription_id,
      subscription_status: 'active',
      subscription_end_date: end_date
    )
  end
  
  def handle_successful_payment_renewal(invoice)
    user = User.find_by(stripe_customer_id: invoice['customer'])
    return unless user
    
    subscription = Stripe::Subscription.retrieve(invoice['subscription'])
    end_date = Time.at(subscription.current_period_end)
    
    user.update!(
      subscription_status: 'active',
      subscription_end_date: end_date
    )
  end
  
  def handle_subscription_cancellation(subscription)
    user = User.find_by(stripe_subscription_id: subscription['id'])
    return unless user
    
    Rails.logger.info "Handling subscription cancellation for user: #{user.email}"
    
    # Check if the subscription is canceled immediately or at period end
    if subscription['cancel_at_period_end']
      # Subscription will continue until period end
      Rails.logger.info "Subscription marked to cancel at period end: #{Time.at(subscription['current_period_end'])}"
      user.update!(
        subscription_status: 'canceled',
        subscription_end_date: Time.at(subscription['current_period_end'])
      )
    else
      # Subscription canceled immediately
      Rails.logger.info "Subscription canceled immediately"
      user.update!(
        subscription_status: 'canceled',
        subscription_end_date: Time.current
      )
    end
  end
end 
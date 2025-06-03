class AccountController < ApplicationController
  before_action :require_login
  
  def show
    @user = current_user
    @subscription_details = get_subscription_details if @user.subscribed?
  end
  
  def cancel_subscription
    Rails.logger.info "=== CANCELING SUBSCRIPTION FOR #{current_user.email} ==="
    
    unless current_user.subscribed?
      flash[:alert] = "You don't have an active subscription to cancel."
      redirect_to account_path
      return
    end
    
    begin
      # Cancel the subscription in Stripe
      subscription = Stripe::Subscription.update(
        current_user.stripe_subscription_id,
        { cancel_at_period_end: true }
      )
      
      Rails.logger.info "Stripe subscription marked for cancellation: #{subscription.id}"
      
      # Update the user's subscription status
      current_user.update!(subscription_status: 'canceled')
      
      flash[:notice] = "Your subscription has been canceled. You'll continue to have access until #{current_user.subscription_end_date.strftime('%B %d, %Y')}."
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error canceling subscription: #{e.message}"
      flash[:alert] = "There was an error canceling your subscription: #{e.message}"
    rescue => e
      Rails.logger.error "General error canceling subscription: #{e.message}"
      flash[:alert] = "An unexpected error occurred. Please try again or contact support."
    end
    
    redirect_to account_path
  end
  
  def reactivate_subscription
    Rails.logger.info "=== REACTIVATING SUBSCRIPTION FOR #{current_user.email} ==="
    
    unless current_user.stripe_subscription_id.present?
      flash[:alert] = "No subscription found to reactivate."
      redirect_to account_path
      return
    end
    
    begin
      # Reactivate the subscription in Stripe
      subscription = Stripe::Subscription.update(
        current_user.stripe_subscription_id,
        { cancel_at_period_end: false }
      )
      
      Rails.logger.info "Stripe subscription reactivated: #{subscription.id}"
      
      # Update the user's subscription status
      current_user.update!(subscription_status: 'active')
      
      flash[:notice] = "Your subscription has been reactivated. Welcome back!"
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error reactivating subscription: #{e.message}"
      flash[:alert] = "There was an error reactivating your subscription: #{e.message}"
    rescue => e
      Rails.logger.error "General error reactivating subscription: #{e.message}"
      flash[:alert] = "An unexpected error occurred. Please try again or contact support."
    end
    
    redirect_to account_path
  end
  
  private
  
  def get_subscription_details
    return nil unless current_user.stripe_subscription_id.present?
    
    begin
      subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
      
      Rails.logger.info "=== SUBSCRIPTION DEBUG ==="
      Rails.logger.info "Subscription ID: #{subscription.id}"
      Rails.logger.info "Status: #{subscription.status}"
      Rails.logger.info "Current period start: #{subscription['current_period_start']} (#{subscription['current_period_start'].class})"
      Rails.logger.info "Current period end: #{subscription['current_period_end']} (#{subscription['current_period_end'].class})"
      Rails.logger.info "Cancel at period end: #{subscription['cancel_at_period_end']}"
      Rails.logger.info "Canceled at: #{subscription['canceled_at']}"
      
      # Handle potential nil values
      period_start = subscription['current_period_start']
      period_end = subscription['current_period_end']
      canceled_at = subscription['canceled_at']
      
      {
        id: subscription.id,
        status: subscription.status,
        current_period_start: period_start ? Time.at(period_start) : nil,
        current_period_end: period_end ? Time.at(period_end) : nil,
        cancel_at_period_end: subscription['cancel_at_period_end'] || false,
        canceled_at: canceled_at ? Time.at(canceled_at) : nil
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error fetching subscription details: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "General error fetching subscription details: #{e.message}"
      Rails.logger.error "Error details: #{e.inspect}"
      nil
    end
  end
end 
require 'stripe'

class User < ApplicationRecord
  has_secure_password
  has_many :floorplans
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  # Usage limits
  FREE_TIER_MONTHLY_LIMIT = 3
  
  def admin?
    # Use the admin column to determine if user is an admin
    admin == true
  end
  
  def subscribed?
    subscription_status == 'active' && subscription_end_date&.future?
  end
  
  def subscription_expired?
    subscription_status == 'canceled' || (subscription_end_date && subscription_end_date.past?)
  end
  
  def subscription_canceled_but_active?
    subscription_status == 'canceled' && subscription_end_date&.future?
  end
  
  def subscription_will_renew?
    subscription_status == 'active' && !subscription_canceled_but_active?
  end
  
  def days_until_subscription_ends
    return nil unless subscription_end_date
    (subscription_end_date.to_date - Date.current).to_i
  end
  
  def subscription_status_display
    case subscription_status
    when 'active'
      subscription_canceled_but_active? ? 'Canceled (Active until end of period)' : 'Active'
    when 'canceled'
      subscription_end_date&.future? ? 'Canceled (Active until end of period)' : 'Canceled'
    else
      'No subscription'
    end
  end
  
  # Usage limit methods
  def has_unlimited_generations?
    subscribed? || admin?
  end
  
  def image_generations_remaining
    return Float::INFINITY if has_unlimited_generations?
    
    reset_usage_if_new_month!
    FREE_TIER_MONTHLY_LIMIT - image_generations_used
  end
  
  def can_generate_image?
    has_unlimited_generations? || image_generations_remaining > 0
  end
  
  def increment_image_generations!
    return true if has_unlimited_generations?
    
    reset_usage_if_new_month!
    
    if can_generate_image?
      increment!(:image_generations_used)
      true
    else
      false
    end
  end
  
  def usage_percentage
    return 0 if has_unlimited_generations?
    
    reset_usage_if_new_month!
    (image_generations_used.to_f / FREE_TIER_MONTHLY_LIMIT * 100).round
  end
  
  def next_reset_date
    return nil if has_unlimited_generations?
    
    reset_at = image_generations_reset_at || Time.current
    reset_at.beginning_of_month.next_month
  end
  
  private
  
  def reset_usage_if_new_month!
    now = Time.current
    reset_at = image_generations_reset_at || now
    
    if reset_at.nil? || reset_at.month != now.month || reset_at.year != now.year
      update!(
        image_generations_used: 0,
        image_generations_reset_at: now.beginning_of_month
      )
    end
  end
  
  def create_stripe_customer!
    return if stripe_customer_id.present?
    
    customer = Stripe::Customer.create(
      email: email,
      name: email.split('@').first
    )
    
    update!(stripe_customer_id: customer.id)
    customer
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error creating customer: #{e.message}"
    raise e
  end
end

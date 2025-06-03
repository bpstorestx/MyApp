require 'stripe'

class User < ApplicationRecord
  has_secure_password
  has_many :floorplans
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
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

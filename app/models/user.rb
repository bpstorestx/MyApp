class User < ApplicationRecord
  has_secure_password
  has_many :floorplans
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  def admin?
    # Use the admin column to determine if user is an admin
    admin == true
  end
end

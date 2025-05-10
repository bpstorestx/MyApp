class Photo < ApplicationRecord
  has_one_attached :original_image
  
  validates :status, presence: true
  
  # Define possible statuses
  enum :status, {
    pending: "pending",
    processing: "processing", 
    completed: "completed",
    failed: "failed"
  }, default: :pending
end

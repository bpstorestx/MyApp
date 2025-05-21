class Floorplan < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :original_image
  has_one_attached :generated_image

  validates :original_image, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
end 
class AddUsageLimitsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :image_generations_used, :integer, default: 0, null: false
    add_column :users, :image_generations_reset_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  end
end

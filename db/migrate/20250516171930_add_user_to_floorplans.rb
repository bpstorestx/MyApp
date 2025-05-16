class AddUserToFloorplans < ActiveRecord::Migration[8.0]
  def change
    add_reference :floorplans, :user, null: true, foreign_key: true
  end
end

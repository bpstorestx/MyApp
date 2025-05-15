class CreateFloorplans < ActiveRecord::Migration[8.0]
  def change
    create_table :floorplans do |t|
      t.string :status, default: 'pending'
      t.string :generated_image_url

      t.timestamps
    end
  end
end 
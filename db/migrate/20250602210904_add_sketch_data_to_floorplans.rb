class AddSketchDataToFloorplans < ActiveRecord::Migration[8.0]
  def change
    add_column :floorplans, :sketch_data, :text
  end
end

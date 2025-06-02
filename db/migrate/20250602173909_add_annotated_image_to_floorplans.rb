class AddAnnotatedImageToFloorplans < ActiveRecord::Migration[8.0]
  def change
    add_column :floorplans, :use_annotated_image, :boolean, default: false
  end
end

class AddCustomPromptToFloorplans < ActiveRecord::Migration[8.0]
  def change
    add_column :floorplans, :custom_prompt, :text
  end
end

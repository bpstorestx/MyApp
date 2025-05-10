class CreatePhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :photos do |t|
      t.string :status
      t.string :ai_image_url

      t.timestamps
    end
  end
end

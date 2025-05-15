namespace :floorplans do
  desc "Update all floorplans to use the new placeholder URL"
  task update_urls: :environment do
    puts "Updating floorplan URLs..."
    
    old_url = "https://via.placeholder.com/1024x1024.png?text=Generated+Layout"
    new_url = "https://placehold.co/400.png"
    
    count = Floorplan.where(generated_image_url: old_url).update_all(
      generated_image_url: new_url
    )
    
    puts "Updated #{count} floorplan records."
  end
end 
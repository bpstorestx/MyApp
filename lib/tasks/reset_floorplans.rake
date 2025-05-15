namespace :floorplans do
  desc "Reset all floorplans"
  task reset: :environment do
    puts "Deleting all floorplan records..."
    
    count = Floorplan.count
    Floorplan.destroy_all
    
    puts "Deleted #{count} floorplan records."
  end
end 
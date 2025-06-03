namespace :test do
  desc "Test image resizing functionality"
  task resize_image: :environment do
    # Find a floorplan with an image
    floorplan = Floorplan.joins(:original_image_attachment).first
    
    if floorplan.nil?
      puts "No floorplans with images found. Test cannot continue."
      next
    end
    
    puts "Found floorplan ##{floorplan.id} with original image"
    
    # Get original image dimensions
    original_dimensions = nil
    floorplan.original_image.open do |file|
      img = MiniMagick::Image.read(file)
      original_dimensions = [img[:width], img[:height]]
    end
    
    puts "Original image dimensions: #{original_dimensions[0]}x#{original_dimensions[1]}"
    puts "Original aspect ratio: #{(original_dimensions[0].to_f / original_dimensions[1]).round(2)}:1"
    
    # Test the ImageResizer
    puts "Testing image resizing with aspect ratio preservation..."
    resized_file = ImageResizer.resize(floorplan.original_image)
    
    if resized_file.nil?
      puts "Resizing failed!"
      next
    end
    
    # Get resized dimensions
    resized_dimensions = nil
    img = MiniMagick::Image.open(resized_file.path)
    resized_dimensions = [img[:width], img[:height]]
    
    puts "Resized image dimensions: #{resized_dimensions[0]}x#{resized_dimensions[1]}"
    puts "Resized aspect ratio: #{(resized_dimensions[0].to_f / resized_dimensions[1]).round(2)}:1"
    
    # Check if aspect ratio was maintained
    original_ratio = (original_dimensions[0].to_f / original_dimensions[1]).round(2)
    resized_ratio = (resized_dimensions[0].to_f / resized_dimensions[1]).round(2)
    
    if (original_ratio - resized_ratio).abs < 0.01
      puts "✓ Aspect ratio preserved!"
    else
      puts "✗ Aspect ratio changed!"
    end
    
    # Clean up
    resized_file.close
    resized_file.unlink if resized_file.respond_to?(:unlink)
    
    # Success message
    puts "Image resizing test completed successfully!"
    puts "Original: #{original_dimensions[0]}x#{original_dimensions[1]} -> Resized: #{resized_dimensions[0]}x#{resized_dimensions[1]}"
  end
end 
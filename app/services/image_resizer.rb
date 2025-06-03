class ImageResizer
  def self.resize(image, max_dimension = 1024)
    tempfile = Tempfile.create(['resized', File.extname(image.filename.to_s)], binmode: true)
    
    begin
      image.open do |file|
        # Use MiniMagick to resize the image
        mini_image = MiniMagick::Image.read(file)
        
        # Get original dimensions
        original_width = mini_image[:width]
        original_height = mini_image[:height]
        
        # Calculate new dimensions while maintaining aspect ratio
        if original_width > original_height
          # Width is larger, so resize based on width
          new_width = max_dimension
          new_height = (original_height.to_f / original_width * max_dimension).round
        else
          # Height is larger, so resize based on height
          new_height = max_dimension
          new_width = (original_width.to_f / original_height * max_dimension).round
        end
        
        # Log the resize operation
        Rails.logger.info("Resizing image from #{original_width}x#{original_height} to #{new_width}x#{new_height} (maintaining aspect ratio)")
        
        mini_image.resize "#{new_width}x#{new_height}"
        mini_image.write tempfile.path
      end
      
      tempfile.rewind
      return tempfile
    rescue => e
      Rails.logger.error("Error resizing image: #{e.message}")
      tempfile.close
      tempfile.unlink if tempfile.respond_to?(:unlink)
      return nil
    end
  end
end 
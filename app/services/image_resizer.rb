class ImageResizer
  def self.resize(image, max_dimension = 1024)
    # Create a temporary file with .png extension
    tempfile = Tempfile.new(['resized_', '.png'])
    tempfile.binmode
    
    begin
      image.open do |file|
        # Use MiniMagick to resize the image
        mini_image = MiniMagick::Image.read(file)
        
        # Get original dimensions and format
        original_width = mini_image[:width]
        original_height = mini_image[:height]
        original_format = mini_image[:format]
        
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
        
        # Log the conversion details
        Rails.logger.info("Converting #{original_format} image from #{original_width}x#{original_height} to PNG #{new_width}x#{new_height}")
        
        # Resize the image
        mini_image.resize "#{new_width}x#{new_height}"
        
        # Convert to PNG and write to file
        mini_image.format 'png'
        mini_image.write tempfile.path
        
        # Rewind the file for reading
        tempfile.rewind
      end
      
      return tempfile
    rescue => e
      Rails.logger.error("Error resizing image: #{e.message}")
      tempfile.close
      tempfile.unlink if tempfile.respond_to?(:unlink)
      return nil
    end
  end
end 
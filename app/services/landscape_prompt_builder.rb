class LandscapePromptBuilder
  attr_reader :photo, :dimensions

  def initialize(photo)
    @photo = photo
    @dimensions = determine_dimensions
    @client = OpenAI::Client.new # Will automatically use the configured API key
  end

  def process
    # Update status to show processing has begun
    photo.update!(status: "processing")
    
    # Use the actual OpenAI API if key is present, fallback to dummy if not
    if ENV["OPENAI_API_KEY"].present?
      # Process the uploaded image to create an enhanced version
      ai_image_url = generate_landscape_image
    else
      ai_image_url = generate_dummy_image_url
    end
    
    # Update the photo with the generated image URL
    photo.update!(
      ai_image_url: ai_image_url,
      status: "completed"
    )
    
    photo
  end

  private

  def determine_dimensions
    return { width: 1024, height: 768 } unless photo.original_image.attached?
    
    # In a real implementation, we would analyze the image dimensions
    # For this dummy version, we're using fixed dimensions
    { width: 1024, height: 768 }
  end

  def load_design_templates
    # This would load design templates from database or configuration
    # For now, we'll return a dummy template
    {
      style: "modern",
      plants: ["native", "drought-resistant"],
      features: ["pathway", "lighting", "garden bed"]
    }
  end

  def load_global_constraints
    # This would load global constraints (e.g., climate considerations)
    # For now, we'll return dummy constraints
    {
      climate: "temperate",
      water_conservation: true,
      maintenance_level: "low"
    }
  end

  def generate_dummy_image_url
    width = dimensions[:width]
    height = dimensions[:height]
    
    # Create a placeholder URL with dimensions
    "https://placehold.co/#{width}x#{height}"
  end
  
  # Generate landscape image using the gpt-image-1 model
  def generate_landscape_image
    begin
      # Download the original image if attached
      original_image_path = nil
      if photo.original_image.attached?
        original_image_path = download_blob_to_tempfile(photo.original_image.blob)
        Rails.logger.debug("Downloaded original image to: #{original_image_path}")
      end

      # Build a descriptive prompt based on the design templates
      prompt = build_prompt
      Rails.logger.debug("Using prompt: #{prompt}")
      
      # Call OpenAI API to generate an image with gpt-image-1 model
      parameters = {
        model: "gpt-image-1",
        prompt: prompt,
        n: 1
      }
      
      # Add the image parameter if we have an original image
      if original_image_path && File.exist?(original_image_path)
        parameters[:image] = File.open(original_image_path, "rb")
        Rails.logger.debug("Added input image to request")
      end
      
      Rails.logger.debug("Calling OpenAI images API with model: gpt-image-1")
      response = @client.images.generate(parameters: parameters)
      
      # Log the response for debugging
      Rails.logger.debug("OpenAI API responded successfully")
      
      # Extract and return the image URL from the response
      if response["data"] && response["data"][0] && response["data"][0]["url"]
        image_url = response["data"][0]["url"]
        Rails.logger.debug("Generated image URL: #{image_url[0..30]}...")
        return image_url
      else
        Rails.logger.error("No URL found in API response")
        return generate_dummy_image_url
      end
    rescue => e
      # Log the detailed error
      Rails.logger.error("OpenAI API Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      generate_dummy_image_url
    ensure
      # Clean up temporary files
      begin
        File.unlink(original_image_path) if original_image_path && File.exist?(original_image_path)
      rescue => e
        Rails.logger.error("Error removing temporary file: #{e.message}")
      end
    end
  end
  
  def build_prompt
    templates = load_design_templates
    constraints = load_global_constraints
    
    # Construct a detailed prompt for the AI image generation
    # This prompt is designed to generate a landscaped version of the property
    <<~PROMPT
      Generate a photorealistic enhanced landscaping design for a residential property.
      
      Design details:
      - Style: #{templates[:style]}
      - Plants: #{templates[:plants].join(', ')}
      - Features: #{templates[:features].join(', ')}
      
      Requirements:
      - Climate consideration: #{constraints[:climate]}
      - Water conservation: #{constraints[:water_conservation] ? 'Required' : 'Optional'}
      - Maintenance level: #{constraints[:maintenance_level]}
      
      The image should be a realistic photo, not a drawing or cartoon.
      Show a beautiful home with perfect landscaping including well-manicured lawn, garden beds with flowers,
      decorative stone pathways, and proper lighting. The landscaping should frame the home
      and enhance its architectural features.
    PROMPT
  end
  
  # Helper method to download a blob to a temporary file
  def download_blob_to_tempfile(blob)
    # Create a temporary file with the right extension
    extension = blob.filename.extension_without_delimiter
    temp_file = Tempfile.new(['landscape', ".#{extension}"])
    temp_file.binmode
    
    # Download the blob data to the temp file
    blob.download do |chunk|
      temp_file.write(chunk)
    end
    
    temp_file.flush
    temp_file.close
    
    # Return the path to the temporary file
    temp_file.path
  end
end 
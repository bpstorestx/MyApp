require 'base64'

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
    
    # Use the OpenAI API if key is present, fallback to dummy if not
    if ENV["OPENAI_API_KEY"].present?
      # Process the uploaded image to create an enhanced version
      ai_image_url = generate_with_gpt_image_1
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
  
  # Generate landscape image using ONLY the gpt-image-1 model
  def generate_with_gpt_image_1
    begin
      # Ensure we have an original image to work with
      unless photo.original_image.attached?
        Rails.logger.error("No image attached to photo")
        return generate_dummy_image_url
      end
      
      # Download the original image to a temporary file
      original_image_path = download_blob_to_tempfile(photo.original_image.blob)
      Rails.logger.debug("Downloaded original image to: #{original_image_path}")
      
      # Open the image file for binary reading
      image_data = File.binread(original_image_path)
      base64_image = Base64.strict_encode64(image_data)
      
      # Create a detailed prompt for landscape enhancement
      prompt = build_prompt
      Rails.logger.debug("Using prompt: #{prompt}")
      
      # Set up parameters for the gpt-image-1 model
      Rails.logger.debug("Calling OpenAI API with gpt-image-1 model")
      response = @client.images.edit(
        parameters: {
          model: "gpt-image-1",
          image: base64_image,
          prompt: prompt,
          n: 1
        }
      )
      
      # Extract the URL from the response
      if response["data"] && response["data"][0] && response["data"][0]["url"]
        image_url = response["data"][0]["url"]
        Rails.logger.debug("Successfully generated enhanced image: #{image_url[0..30]}...")
        return image_url
      else
        # If no URL in response, log and use dummy
        Rails.logger.error("No URL in API response: #{response.inspect}")
        return generate_dummy_image_url
      end
    rescue => e
      # Log error and use dummy image
      Rails.logger.error("gpt-image-1 API error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return generate_dummy_image_url
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
      Transform this property photo with enhanced landscaping.
      
      Design details:
      - Style: #{templates[:style]}
      - Plants: #{templates[:plants].join(', ')}
      - Features: #{templates[:features].join(', ')}
      
      Requirements:
      - Climate consideration: #{constraints[:climate]}
      - Water conservation: #{constraints[:water_conservation] ? 'Required' : 'Optional'}
      - Maintenance level: #{constraints[:maintenance_level]}
      
      The result should be a realistic photo with beautiful landscaping including:
      - Well-manicured lawn
      - Garden beds with colorful flowering plants
      - Decorative stone pathways
      - Landscape lighting features
      - The landscaping should frame the home and enhance its architectural features
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
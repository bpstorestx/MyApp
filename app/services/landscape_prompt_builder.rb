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
      ai_image_url = generate_ai_image
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
  
  def generate_ai_image
    # Build the prompt for image generation
    prompt = build_prompt
    
    begin
      # Call OpenAI API to generate the image
      response = @client.images.generate(
        parameters: {
          prompt: prompt,
          model: "dall-e-3", # Use DALL-E 3 for higher quality
          size: "1024x1024",
          quality: "standard",
          n: 1
        }
      )
      
      # Extract and return the image URL from the response
      response.dig("data", 0, "url")
    rescue => e
      # Log the error and fallback to dummy image
      Rails.logger.error("OpenAI API Error: #{e.message}")
      generate_dummy_image_url
    end
  end
  
  def build_prompt
    templates = load_design_templates
    constraints = load_global_constraints
    
    # Construct a detailed prompt for the AI image generation
    <<~PROMPT
      Transform this residential property photo into an enhanced landscape design with the following features:
      
      Style: #{templates[:style]}
      Plants: #{templates[:plants].join(', ')}
      Features: #{templates[:features].join(', ')}
      
      Constraints:
      - Climate: #{constraints[:climate]}
      - Water conservation: #{constraints[:water_conservation] ? 'Required' : 'Optional'}
      - Maintenance level: #{constraints[:maintenance_level]}
      
      Create a photorealistic rendering that maintains the home's architecture while beautifying the landscape.
    PROMPT
  end
end 
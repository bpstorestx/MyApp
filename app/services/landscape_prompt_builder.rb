class LandscapePromptBuilder
  attr_reader :photo, :dimensions

  def initialize(photo)
    @photo = photo
    @dimensions = determine_dimensions
  end

  def process
    # Update status to show processing has begun
    photo.update!(status: "processing")
    
    # In a real implementation, this would call OpenAI or another service
    # For now, we're using a dummy placeholder as specified in the requirements
    dummy_url = generate_dummy_image_url
    
    # Update the photo with the "enhanced" image URL
    photo.update!(
      ai_image_url: dummy_url,
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
end 
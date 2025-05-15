class FloorplanGenerator
  def initialize(floorplan)
    @floorplan = floorplan
  end

  def generate
    # Dummy layout generator for now - will replace with OpenAI API later
    dummy_url = "https://placehold.co/400.png"
    
    # Update the floorplan with the generated layout URL
    @floorplan.update!(
      generated_image_url: dummy_url,
      status: "completed"
    )
  rescue => e
    Rails.logger.error("Layout generation failed: #{e.message}")
    @floorplan.update!(status: "failed")
  end
end 
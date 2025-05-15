class FloorplanGenerator
  require "net/http"
  require "uri"
  require "json"
  require "base64"
  require 'tempfile'
  
  REQUIRED_IMAGES = [
    'body-lotion.png',
    'bath-bomb.png',
    'incense-kit.png',
    'soap.png'
  ]
  
  def initialize(floorplan)
    @floorplan = floorplan
  end

  def generate
    Rails.logger.info("OpenAI API Key present: #{ENV['OPENAI_API_KEY'].present?}")
    if openai_available?
      Rails.logger.info("Using OpenAI for generation")
      generate_with_openai
    else
      Rails.logger.info("Falling back to dummy layout - OpenAI not available")
      generate_dummy_layout
    end
  rescue => e
    Rails.logger.error("Layout generation failed: #{e.message}")
    @floorplan.update!(status: "failed")
  end
  
  private
  
  def openai_available?
    !ENV["OPENAI_API_KEY"].nil?
  end
  
  def generate_dummy_layout
    dummy_url = "https://placehold.co/402x401.png"
    @floorplan.update!(
      generated_image_url: dummy_url,
      status: "completed"
    )
  end
  
  def generate_with_openai
    # Set up the API endpoint
    uri = URI.parse("https://api.openai.com/v1/images/edits")
    
    # Create multipart form data
    boundary = "AaB03x"
    post_body = []
    
    # Add model parameter
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n"
    post_body << "gpt-image-1\r\n"
    
    # Add input image
    image_path = "2 Test Floorplan.JPG"
    unless File.exist?(image_path)
      raise "Required input image not found: #{image_path}"
    end
    
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"image\"; filename=\"#{File.basename(image_path)}\"\r\n"
    post_body << "Content-Type: image/jpeg\r\n\r\n"
    post_body << File.binread(image_path)
    post_body << "\r\n"
    
    # Add prompt
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
    post_body << "Convert this into a clean, top-down architectural image of a professional office layout. Include a large open common area in the center and private offices along the perimeter. Keep the structure realistic with clear walls, windows, and entry points. Exclude bathrooms, furniture, and decorations. Style should be blueprint-like and lease-ready.\r\n"
    
    # Add closing boundary
    post_body << "--#{boundary}--\r\n"
    
    # Create and configure the request
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = post_body.join
    
    # Make the request
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    # Process the response
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      if result["data"] && result["data"][0] && result["data"][0]["b64_json"]
        # Save the base64 decoded image to a file
        output_path = Rails.root.join('public', 'generated_images', 'floorplan.png')
        FileUtils.mkdir_p(File.dirname(output_path))
        
        File.open(output_path, 'wb') do |f|
          f.write(Base64.decode64(result["data"][0]["b64_json"]))
        end
        
        # Update the floorplan with the generated image URL
        @floorplan.update!(
          generated_image_url: "/generated_images/floorplan.png",
          status: "completed"
        )
      else
        raise "Invalid response format from OpenAI API"
      end
    else
      raise "OpenAI API request failed: #{response.code} - #{response.body}"
    end
  end
end 
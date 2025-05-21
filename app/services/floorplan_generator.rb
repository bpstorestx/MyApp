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
    # Create a unique dummy URL using the floorplan ID
    dummy_url = "https://placehold.co/400x400/CCCCCC/333333.png?text=Floorplan+#{@floorplan.id}"
    @floorplan.update!(
      generated_image_url: dummy_url,
      status: "completed"
    )
  end
  
  def generate_with_openai
    unless @floorplan.original_image.attached?
      raise "No original image attached to floorplan"
    end

    # Set up the API endpoint
    uri = URI.parse("https://api.openai.com/v1/images/edits")
    
    # Create multipart form data
    boundary = "AaB03x"
    post_body = []
    
    # Add model parameter
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n"
    post_body << "gpt-image-1\r\n"
    
    # Create a temporary file from the uploaded image
    Tempfile.create(['input', '.jpg']) do |temp_file|
      temp_file.binmode
      temp_file.write(@floorplan.original_image.download)
      temp_file.rewind
      
      post_body << "--#{boundary}\r\n"
      post_body << "Content-Disposition: form-data; name=\"image\"; filename=\"#{@floorplan.original_image.filename}\"\r\n"
      post_body << "Content-Type: #{@floorplan.original_image.content_type}\r\n\r\n"
      post_body << temp_file.read
      post_body << "\r\n"
    end
    
    # Add prompt
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
    post_body << "Convert this into a clean, top-down architectural image of a professional office layout. Include a large open common area in the center and private offices along the perimeter. Keep the outline the same with the same windows and entry points. Exclude bathrooms, furniture, and decorations. Style should be blueprint-like and lease-ready.\r\n"
    
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
        # Create a unique filename
        filename = "floorplan_#{@floorplan.id}.png"
        
        # Create a temporary file with the decoded image data
        Tempfile.create([filename, '.png'], binmode: true) do |file|
          file.write(Base64.decode64(result["data"][0]["b64_json"]))
          file.rewind
          
          # Attach the generated image to the floorplan using ActiveStorage
          @floorplan.generated_image.attach(
            io: file,
            filename: filename,
            content_type: 'image/png'
          )
        end
        
        # Update the floorplan status to completed
        @floorplan.update!(status: "completed")
      else
        raise "Invalid response format from OpenAI API"
      end
    else
      raise "OpenAI API request failed: #{response.code} - #{response.body}"
    end
  end
end 
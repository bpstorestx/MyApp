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

  def generate(use_sketch = false)
    Rails.logger.info("OpenAI API Key present: #{ENV['OPENAI_API_KEY'].present?}")
    if openai_available?
      Rails.logger.info("Using OpenAI for generation")
      if use_sketch && @floorplan.sketched_image.attached?
        Rails.logger.info("Using sketch data for generation with SKETCHED PROMPTING strategy")
        generate_with_openai_from_sketch
      else
        Rails.logger.info("Using original image for generation with STANDARD PROMPTING strategy")
        generate_with_openai
      end
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
    
    # Resize and create a temporary file from the uploaded image
    resized_file = ImageResizer.resize(@floorplan.original_image)
    
    if resized_file
      post_body << "--#{boundary}\r\n"
      post_body << "Content-Disposition: form-data; name=\"image\"; filename=\"#{@floorplan.original_image.filename}\"\r\n"
      post_body << "Content-Type: image/png\r\n\r\n"
      post_body << resized_file.read
      post_body << "\r\n"
      
      # Add prompt parameter
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
      
      # Make sure to close and delete the temp file
      resized_file.close
      resized_file.unlink if resized_file.respond_to?(:unlink)
    else
      raise "Failed to resize the image"
    end
  end
  
  def generate_with_openai_from_sketch
    unless @floorplan.sketched_image.attached?
      raise "No sketched image attached to floorplan"
    end

    # Extract text elements from sketch_data if available
    text_elements = extract_text_from_sketch
    
    # Set up the API endpoint
    uri = URI.parse("https://api.openai.com/v1/images/edits")
    
    # Create multipart form data
    boundary = "AaB03x"
    post_body = []
    
    # Add model parameter
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n"
    post_body << "gpt-image-1\r\n"
    
    # Resize and create a temporary file from the sketched image
    resized_file = ImageResizer.resize(@floorplan.sketched_image)
    
    if resized_file
      post_body << "--#{boundary}\r\n"
      post_body << "Content-Disposition: form-data; name=\"image\"; filename=\"sketch_#{@floorplan.id}.png\"\r\n"
      post_body << "Content-Type: image/png\r\n\r\n"
      post_body << resized_file.read
      post_body << "\r\n"
      
      # Add prompt parameter
      post_body << "--#{boundary}\r\n"
      post_body << "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
      post_body << "You are a master architect specializing in modern efficient office space design. Your work emphasizes flow of a workspace with doors and open layout combining for efficiency. "
      post_body << "For this project you are advising a commercial real estate client. He has provided you a floorplan and sketched out what he wants added. "
      post_body << "Do not adjust any *exterior walls or exterior doors*. "
      post_body << "Generate an updated floorplan using his sketched lines and text notes that were drawn in the floorplan provided"
      
      # Add text elements from the sketch if available
      if text_elements.any?
        post_body << " including these text annotations: #{text_elements.join(', ')}.\r\n"
      else
        post_body << ".\r\n"
      end
      
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
      
      # Make sure to close and delete the temp file
      resized_file.close
      resized_file.unlink if resized_file.respond_to?(:unlink)
    else
      raise "Failed to resize the image"
    end
  end
  
  # Helper method to extract text elements from sketch_data
  def extract_text_from_sketch
    return [] unless @floorplan.sketch_data.present?
    
    begin
      # Parse the sketch data JSON
      sketch_data = JSON.parse(@floorplan.sketch_data)
      
      # Extract text objects
      text_objects = sketch_data['objects']&.select { |obj| obj['type'] == 'text' } || []
      
      # Return the text content of each text object
      text_objects.map { |obj| obj['text'] }.reject(&:empty?)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse sketch data: #{e.message}")
      []
    end
  end
end 
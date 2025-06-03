class FloorplansController < ApplicationController
  # Explicitly require the FloorplanGenerator
  require_relative '../services/floorplan_generator'
  require_relative '../workers/floorplan_worker'
  before_action :require_login, only: [:index]
  
  def index
    @floorplans = current_user.floorplans if logged_in?
  end

  def my_floorplans
    @floorplans = Floorplan.order(created_at: :desc)
  end

  def new
    @floorplan = Floorplan.new
  end

  def create
    # Extract sketch_after_upload parameter before creating the floorplan model
    sketch_after_upload = params[:floorplan][:sketch_after_upload] == "1"
    
    @floorplan = Floorplan.new(floorplan_params)
    @floorplan.status = 'pending'
    
    # Associate with current user if logged in
    @floorplan.user = current_user if logged_in?

    if @floorplan.save
      # Enqueue the worker to process the floorplan asynchronously
      FloorplanWorker.perform_async(@floorplan.id)
      
      # Redirect to sketch page if the checkbox was checked
      if sketch_after_upload
        redirect_to sketch_floorplan_path(@floorplan), notice: 'Floorplan was successfully uploaded. You can now sketch on it.'
      else
        redirect_to @floorplan, notice: 'Floorplan was successfully uploaded and is being processed.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @floorplan = Floorplan.find(params[:id])
    
    # Force update the URL for this floorplan to use the new placeholder
    if @floorplan.generated_image_url && @floorplan.generated_image_url.include?("via.placeholder.com")
      @floorplan.update(generated_image_url: "https://placehold.co/400.png")
    end
  end
  
  def sketch
    @floorplan = Floorplan.find(params[:id])
    @use_generated = params[:use_generated] == 'true'
  end
  
  def save_sketch
    @floorplan = Floorplan.find(params[:id])
    
    # Parse the JSON request
    sketch_data = JSON.parse(request.body.read)
    
    if sketch_data['sketch_image'].present?
      # Process the base64 image data
      image_data = sketch_data['sketch_image'].sub(/^data:image\/\w+;base64,/, '')
      decoded_image = Base64.decode64(image_data)
      
      # Create a temporary file
      temp_file = Tempfile.new(['sketch_', '.png'])
      temp_file.binmode
      temp_file.write(decoded_image)
      temp_file.rewind
      
      # Attach the sketched image to the floorplan
      @floorplan.sketched_image.attach(
        io: temp_file,
        filename: "sketch_#{@floorplan.id}.png",
        content_type: 'image/png'
      )
      
      # Store the canvas JSON data if present
      if sketch_data['sketch_data'].present?
        @floorplan.update(
          sketch_data: sketch_data['sketch_data'],
          status: 'sketch_submitted'
        )
      else
        @floorplan.update(status: 'sketch_submitted')
      end
      
      # Close and delete the temp file
      temp_file.close
      temp_file.unlink
      
      # Re-process the floorplan with the sketch data
      FloorplanWorker.perform_async(@floorplan.id, true) # true indicates to use sketch data
      
      render json: { 
        success: true, 
        message: 'Sketch saved successfully',
        redirect_url: floorplan_path(@floorplan)
      }
    else
      render json: { success: false, message: 'No sketch data received' }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("Error saving sketch: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  private

  def floorplan_params
    # Explicitly exclude sketch_after_upload from parameters passed to the model
    params.require(:floorplan).permit(:original_image)
  end
end 
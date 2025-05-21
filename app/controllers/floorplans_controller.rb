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
    @floorplan = Floorplan.new(floorplan_params)
    @floorplan.status = 'pending'
    
    # Associate with current user if logged in
    @floorplan.user = current_user if logged_in?

    if @floorplan.save
      # Enqueue the worker to process the floorplan asynchronously
      FloorplanWorker.perform_async(@floorplan.id)
      redirect_to @floorplan, notice: 'Floorplan was successfully uploaded and is being processed.'
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

  private

  def floorplan_params
    params.require(:floorplan).permit(:original_image)
  end
end 
class FloorplansController < ApplicationController
  # Explicitly require the FloorplanGenerator
  require_relative '../services/floorplan_generator'
  
  def new
    @floorplan = Floorplan.new
  end

  def create
    @floorplan = Floorplan.new(floorplan_params)
    @floorplan.status = 'processing'

    if @floorplan.save
      # Generate the layout after successful upload
      FloorplanGenerator.new(@floorplan).generate
      redirect_to @floorplan, notice: 'Floorplan was successfully uploaded.'
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
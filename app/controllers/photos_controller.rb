class PhotosController < ApplicationController
  def new
    @photo = Photo.new
  end

  def create
    @photo = Photo.new(photo_params)
    @photo.status = "pending"

    if @photo.save
      if @photo.original_image.attached?
        # Use our service to process the photo and generate a dummy enhanced image
        ::LandscapePromptBuilder.new(@photo).process
        
        redirect_to @photo, notice: "Photo was successfully uploaded and enhanced!"
      else
        @photo.destroy
        flash.now[:alert] = "Please attach an image"
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @photo = Photo.find(params[:id])
  end

  private

  def photo_params
    params.require(:photo).permit(:original_image)
  end
end

require 'sidekiq'
require_relative '../services/floorplan_generator'

class FloorplanWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: 'default', retry: 3
  
  def perform(floorplan_id)
    # Find the floorplan by ID
    floorplan = Floorplan.find_by(id: floorplan_id)
    
    return unless floorplan
    
    # Update status to processing if it's still pending
    if floorplan.status == 'pending'
      floorplan.update(status: 'processing')
    end
    
    begin
      # Generate the floorplan layout using the existing service
      FloorplanGenerator.new(floorplan).generate
    rescue => e
      # Log the error and update the floorplan status
      Rails.logger.error("FloorplanWorker failed for floorplan ##{floorplan_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      floorplan.update(status: 'failed')
      
      # Re-raise the error so Sidekiq can handle retries if configured
      raise e
    end
  end
end 
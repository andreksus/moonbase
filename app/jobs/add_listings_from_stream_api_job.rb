class AddListingsFromStreamApiJob < ApplicationJob
  queue_as 'MoonbaseListingsWorker'

  def perform()
    self.class.perform()
  end

  def self.perform()
      if params[:event][:event_type] == "item_listed"
        Listing.create_listing(params[:event])
        render json: {}, status: :ok
      end
    end

end
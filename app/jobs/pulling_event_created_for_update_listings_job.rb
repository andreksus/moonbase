class PullingEventCreatedForUpdateListingsJob < ApplicationJob
  # queue_as 'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1'
  # queue_as 'MoonbaseListingsWorker'

  def perform(start_date, end_date, event_type)
    self.class.perform(start_date, end_date, event_type)
  end

  def self.perform(start_date, end_date, event_type = 'created')
    open_sea = OpenSea.new()
    max_api_items    = 300
    max_iteration    = 100
    iteration_count  = 1
    duplicate_count  = 0
    opensea_response = {}
    was_assets = []


    TempEventListing.where("create_date > ?", DateTime.now.utc - 2.hours).delete_all rescue nil

    while !opensea_response.nil? && opensea_response[:next].present? && iteration_count <= max_iteration || iteration_count == 1
      opensea_response = open_sea.retrieving_events(
        event_type,
        false,
        max_api_items,
        nil,
        nil,
        nil,
        nil,
        nil,
        end_date,
        start_date,
        opensea_response[:next].present? ? opensea_response[:next] : nil
      )

      if (!opensea_response.nil?) && opensea_response[:asset_events].length > 0
        opensea_response[:asset_events].each do |event|
          if event[:asset].present?
            if event[:id].present? && event[:created_date].present?
              unless TempEventListing.where(id: event[:id], created_date: DateTime.parse(event[:created_date]).utc).first
                TempEventListing.create!({id: event[:id], created_date: DateTime.parse(event[:created_date]).utc})
                collection_id = Collection.update_or_create_by(event[:asset][:collection])
                asset_id      = Asset.update_or_create_by_id(event[:asset], collection_id)

                  if event[:asset].present? && event[:asset][:permalink].include?("ethereum") && !event[:listing_time].nil? && !was_assets.include?(event[:asset][:id])
                    asset = Asset.find(asset_id)
                    if asset.present?
                      listings_response = open_sea.retrieving_listings(asset.token_id, asset.contract_address) # см. ниже
                      save_listing(listings_response, asset) #вывести в другую джобу perform_later
                      sleep 1
                    end
                    was_assets.push(event[:asset][:id])
                  end
              else
                duplicate_count += 1
              end
            end
          end
        end
      end
      iteration_count += 1
      Rails.logger.info "Event Type: #{event_type}, iteration_count = #{iteration_count} duplicate_count: #{duplicate_count}"
      break if (!opensea_response.nil? && !opensea_response[:next].present?) || (iteration_count == max_iteration) || opensea_response.nil? || duplicate_count = 40
    end
  end

  def self.save_listing(opensea_response, asset) #ВЫВЕСТИ В ОТДЕЛЬНУЮ ДЖОБУ ЗАМЕНИТЬ НА update_listing_by_asset_id.perform_later

    unless opensea_response.nil?

        # asset.listings.where("expiration_time < ?", DateTime.now.utc).destroy_all
        asset.listings.destroy_all rescue nil

      # unless opensea_response[:listings].length > 0
      #   asset.listings.where("expiration_time < ?", DateTime.now.utc).destroy_all
      # end


      # not_active_listings = asset_listings_in_db.filter_map{|i| i unless opensea_response[:listings].find{|t| t[:order_hash] == i.order_hash}.present?}
      # listings = opensea_response[:listings].filter_map{|i| i unless asset_listings_in_db.find{|t| t.order_hash == i[:order_hash]}.present?}

      # not_active_listings.each do |listing|
      #   listing.destroy_all
      # end
      # listings = opensea_response[:listings] + opensea_response[:seaport_listings]
      listings = opensea_response[:seaport_listings]

      if listings.length > 0
        listings.each do |listing|
          # unless Listing.find_by_order_hash(listing[:order_hash])
          begin
            base_price =  if listing[:payment_token_contract] && listing[:payment_token_contract][:symbol] != "ETH" && listing[:payment_token_contract][:symbol] != "WETH"
                            EventService.get_total_price_by_decimals(listing[:base_price] || listing[:current_price], listing[:payment_token_contract][:decimals]) * listing[:payment_token_contract][:eth_price].to_f
                          else
                            EventService.get_total_price_by_decimals(listing[:base_price] || listing[:current_price], 18)
                          end

            maker_id = Account.update_or_create_by_address(
              listing[:maker][:address],
              listing[:maker][:username] ? listing[:maker][:username] : nil,
              listing[:maker][:profile_img_url] ? listing[:maker][:profile_img_url] : ""
            )

            taker_id = if listing[:taker].present?
                            Account.update_or_create_by_address(
                            listing[:taker][:address],
                            listing[:taker][:username] ? listing[:taker][:username] : nil,
                            listing[:taker][:profile_img_url] ? listing[:taker][:profile_img_url] : ""
                          )
                       else
                         nil
                       end
            Listing.create! do |listing_model|
              listing_model.asset_id = asset.id
              listing_model.base_price = base_price
              # listing_model.quantity = listing[:quantity]
              listing_model.payment_token = listing[:payment_token].to_s
              listing_model.created_date = DateTime.parse(listing[:created_date]).utc
              listing_model.listing_time = Time.at(listing[:listing_time]).utc.to_datetime
              listing_model.expiration_time = Time.at(listing[:expiration_time]).utc.to_datetime
              # listing_model.order_hash = listing[:order_hash].to_s
              listing_model.maker_id = maker_id
              listing_model.taker_id = taker_id
              # listing_model.active = true
            end
          rescue StandardError => e
            Rails.logger.info "ERROR IN SAVING LISTINGS: #{e.message}"
          end
          # end
        end
      end
    end
  end
end

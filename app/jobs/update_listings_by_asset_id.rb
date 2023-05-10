class UpdateListingsByAssetId < ApplicationJob #СДЕЛАТЬ perform_later и распределить между очередями sqs(отправить 10 на один воркер и 10 на другой)
  # queue_as 'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1'
  queue_as 'MoonbaseListingsWorker'

  def perform(asset_id)
    self.class.perform(asset_id)
  end

  def self.perform(asset_id)
    asset = Asset.find(asset_id)
    if asset.present?
      open_sea = OpenSea.new()
      opensea_response = open_sea.retrieving_listings(asset.token_id, asset.contract_address)
      save_listing(opensea_response, asset)
    end
  end

  def self.save_listing(opensea_response, asset)
    unless opensea_response.nil?
      begin
        # asset.listings.where("expiration_time < ?", DateTime.now.utc).destroy_all
        asset.listings.destroy_all
      rescue Exception => e ;end
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

              taker_id = Account.update_or_create_by_address(
                listing[:taker][:address],
                listing[:taker][:username] ? listing[:taker][:username] : nil,
                listing[:taker][:profile_img_url] ? listing[:taker][:profile_img_url] : ""
              )

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
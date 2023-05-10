class Listing < ApplicationRecord
  has_one :asset

  def self.create_listing listing
    # Rails.logger.info "=-=-=-=-=- STARTING create_listing =-=-=-=-=- #{DateTime.now.utc}"
    payload = listing[:payload]
    # Rails.logger.info "=-=-=-=-=- create_listing payload :: #{payload&.inspect} =-=-=-=-=- #{DateTime.now.utc}"
    chain, contract_address, token_id = payload[:item][:nft_id].split('/')
    Rails.logger.info [contract_address, token_id]
    asset = Asset.find_by(contract_address: contract_address, token_id: token_id)
    # sql = "SELECT * FROM assets WHERE contract_address = ('#{contract_address}') AND token_id = ('#{token_id}') LIMIT 1"
    # asset = ActiveRecord::Base.connection.execute(
    # "SELECT id FROM assets WHERE contract_address = ('#{contract_address}') AND token_id = ('#{token_id}') LIMIT 1")
    # Rails.logger.info "=-=-=-=-=- create_listing asset :: #{asset&.inspect} =-=-=-=-=- #{DateTime.now.utc}"
    if asset
      base_price = if payload[:payment_token][:symbol] != "ETH" && payload[:payment_token][:symbol] != "WETH"
                     EventService.get_total_price_by_decimals(
                       payload[:base_price],
                       payload[:payment_token][:decimals]
                     ) * payload[:payment_token][:eth_price].to_f
                   else
                     EventService.get_total_price_by_decimals(payload[:base_price], 18)
                   end
      # Rails.logger.info "=-=-=-=-=- create_listing AFTER get_total_price_by_decimals =-=-=-=-=- #{DateTime.now.utc}"
      maker_id = Account.find_by_address(payload[:maker][:address])&.id || nil if payload[:maker].present?
      taker_id = Account.find_by_address(payload[:taker][:address])&.id || nil if payload[:taker].present?

      # Rails.logger.info "=-=-=-=-=- create_listing AFTER maker_id-taker_id =-=-=-=-=- #{DateTime.now.utc}"
      self.create! do |listing_model|
        listing_model.asset_id = asset.id
        listing_model.token_id = asset.token_id
        listing_model.base_price = base_price
        listing_model.payment_token = listing[:payment_token].to_s
        listing_model.order_hash = payload[:order_hash].to_s
        listing_model.quantity = payload[:quantity]
        listing_model.created_date = DateTime.parse(payload[:event_timestamp]).utc
        listing_model.listing_time = DateTime.parse(payload[:listing_date]).utc
        listing_model.expiration_time = DateTime.parse(payload[:expiration_date]).utc
        listing_model.maker_id = maker_id
        listing_model.taker_id = taker_id
        listing_model.img_url = payload[:item][:metadata][:image_url]
      end
      # Rails.logger.info "=-=-=-=-=- Listing saved listing_model :: #{self.inspect} =-=-=-=-=- #{DateTime.now.utc}"
    end
    # "=-=-=-=-=- FINISHING create_listing =-=-=-=-=- #{DateTime.now.utc}"
  end

  def self.delete_listing event
    order_hash = event[:payload][:order_hash]

    if order_hash
      listing = self.find_by_order_hash(order_hash)
      if listing
        listing.destroy!
      else
        puts "Listing not found"
      end
    end
  end

  # def self.delete_listing item_sale
  # order_hash = item_sale[:payload][:order_hash]
  #
  # if order_hash
  # listing = self.find_by_order_hash(order_hash)
  # if listing
  # listing.destroy!
  # else
  # puts "Listing not found"
  # end
  # end
  # end
end
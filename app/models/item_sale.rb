class ItemSale < ApplicationRecord
  has_one :asset

  def self.create_item_sale item_sale
    payload = item_sale[:payload]
    chain, contract_address, token_id = payload[:item][:nft_id].split('/')
    asset = Asset.find_by(contract_address: contract_address, token_id: token_id)
    if asset
      sale_price =  if payload[:payment_token][:symbol] != "ETH" && payload[:payment_token][:symbol] != "WETH"
                      EventService.get_total_price_by_decimals(
                        payload[:sale_price],
                        payload[:payment_token][:decimals]
                      ) * payload[:payment_token][:eth_price].to_f
                    else
                      EventService.get_total_price_by_decimals(payload[:sale_price], 18)
                    end
      maker_id = Account.find_by_address(payload[:maker][:address])&.id || nil if payload[:maker].present?
      taker_id = Account.find_by_address(payload[:taker][:address])&.id || nil if payload[:taker].present?
      
      self.create! do |sale_model|
        sale_model.asset_id = asset.id
        sale_model.contract_address = contract_address
        sale_model.token_id = asset.token_id
        sale_model.sale_price = sale_price
        sale_model.payment_token = payload[:payment_token][:symbol].to_s.downcase
        sale_model.order_hash = payload[:order_hash].to_s
        sale_model.quantity = payload[:quantity]
        sale_model.created_date = DateTime.parse(payload[:event_timestamp]).utc
        sale_model.maker_id = maker_id
        sale_model.taker_id = taker_id
        sale_model.img_url = payload[:item][:metadata][:image_url]
        sale_model.collection_id = asset.collection_id
      end
    end
  end

end
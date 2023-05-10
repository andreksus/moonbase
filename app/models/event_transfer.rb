class EventTransfer < ApplicationRecord

  def self.save_event opensea_response
    duplicate_count = 0

    if opensea_response[:asset_events].length > 0
      opensea_response[:asset_events].each do |event|
        next unless event[:asset].present?

        begin
          unless self.find_by_id(event[:id])
            seller_account_id = Account.update_or_create_by_address(
              event[:seller][:address],
              event[:seller][:user] ? event[:seller][:user][:username] : nil,
              event[:seller][:profile_img_url] ? event[:seller][:profile_img_url] : ""
            ) if event[:seller].present?

            from_account_id = Account.update_or_create_by_address(
              event[:from_account][:address],
              event[:from_account][:user] ? event[:from_account][:user][:username] : nil,
              event[:from_account][:profile_img_url] ? event[:from_account][:profile_img_url] : ""
            ) if event[:from_account].present?

            to_account_id = Account.update_or_create_by_address(
              event[:to_account][:address],
              event[:to_account][:user] ? event[:to_account][:user][:username] : nil,
              event[:to_account][:profile_img_url] ? event[:to_account][:profile_img_url] : ""
            ) if event[:to_account].present?

            winner_account_id = Account.update_or_create_by_address(
              event[:winner_account][:address],
              event[:winner_account][:user] ? event[:winner_account][:user][:username] : nil,
              event[:winner_account][:profile_img_url] ? event[:winner_account][:profile_img_url] : ""
            ) if event[:winner_account].present?

            collection_id = Collection.update_or_create_by(event[:asset][:collection])
            asset_id = Asset.update_or_create_by_id(event[:asset], collection_id)

            payment_symbol = 'eth'
            payment_symbol = 'klaytn' if event[:asset][:permalink].include?('klaytn')
            payment_symbol = 'matic' if event[:asset][:permalink].include?('matic')

            total_price = nil
            if event[:total_price].present?
              if payment_symbol == 'eth' && event[:payment_token] && event[:payment_token][:symbol] != "ETH" && event[:payment_token][:symbol] != "WETH"
                total_price = EventService.get_total_price_by_decimals(event[:total_price], event[:payment_token][:decimals]) * event[:payment_token][:eth_price].to_f
              else
                total_price = EventService.get_total_price_by_decimals(event[:total_price], 18)
              end
            end


            begin
              self.create! do |event_model|
                event_model.id = event[:id]
                event_model.created_date = DateTime.parse(event[:created_date]).utc
                event_model.quantity = event[:quantity]
                event_model.total_price = total_price
                event_model.asset_id = asset_id
                event_model.collection_id = collection_id
                event_model.seller_account_id = seller_account_id
                event_model.from_account_id = from_account_id
                event_model.to_account_id = to_account_id
                event_model.winner_account_id = winner_account_id
                event_model.transaction_hash = event[:transaction][:transaction_hash]
                event_model.transaction_index = event[:transaction][:transaction_index]
                event_model.block_hash = event[:transaction][:transaction_hash]
                event_model.block_number = event[:transaction][:transaction_index]
              end
            rescue
              duplicate_count += 1
            end
          else
            duplicate_count += 1
          end

        rescue Exception => e
          Rails.logger.info("Event Transfer was not save: #{e.message} #{e.backtrace}")
        end
      end
    end
    duplicate_count
  end
end

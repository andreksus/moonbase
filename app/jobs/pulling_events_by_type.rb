class PullingEventsByType < ApplicationJob
  queue_as ENV['BACKGROUND_WORKER_NUMBER'] == 'second' ? 'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1' : 'awseb-e-xpk2xpwnks-stack-AWSEBWorkerQueue-1PDFAO0R4PSAY'

  def perform(end_date, event_type, user_id)
    self.class.perform(end_date, event_type, user_id)
  end

  def self.perform(end_date, event_type = 'successful', user_id = 'nil')
    open_sea = OpenSea.new()
    unless user_id.nil? || user_id == 'nil'
      user = User.find(user_id)

      user.owned_assets.map{|as| as.asset_id}.each do |asset_id|
        asset = Asset.find asset_id
        pulling_process(open_sea, end_date, asset, event_type)
      end
    else
      pulling_process(open_sea, end_date, nil, event_type)
    end
  end

  def self.pulling_process(open_sea, end_date = nil, asset = nil, event_type = 'successful')
    max_api_items    = 250
    max_iteration    = 100
    iteration_count  = 1
    duplicate_count  = 0
    opensea_response = {}

    if duplicate_count != max_api_items
      while !opensea_response.nil? && opensea_response[:next].present? || iteration_count == 1
        cursor_url = opensea_response[:next].present? ? opensea_response[:next] : nil

        opensea_response = open_sea.retrieving_events(
          event_type,
          false,
          max_api_items,
          nil,
          asset.present? ? asset.token_id : nil,
          asset.present? ? asset.contract_address : nil,
          nil,
          nil,
          asset.present? ? nil : end_date,
          nil,
          cursor_url.present? ? cursor_url : nil
        )

        duplicate_count = event_type == "transfer" ? save_event_transfer(opensea_response) : save_event(opensea_response)

        iteration_count += 1
        sleep 2
        Rails.logger.info "Event Type: #{event_type}, iteration_count = #{iteration_count}, duplicate_count = #{duplicate_count}"

        break if (duplicate_count >= 240 && iteration_count >= 10) || (iteration_count == max_iteration)
      end
    end
  end

  def self.save_event_transfer opensea_response
    duplicate_count = 0

    if !opensea_response.nil? && opensea_response[:asset_events].length > 0
      opensea_response[:asset_events].each do |event|
        next unless event[:asset].present?

        begin
          unless EventTransfer.find_by_id(event[:id])
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
              total_price = if payment_symbol == 'eth' && event[:payment_token] && event[:payment_token][:symbol] != "ETH" && event[:payment_token][:symbol] != "WETH"
                              EventService.get_total_price_by_decimals(event[:total_price], event[:payment_token][:decimals]) * event[:payment_token][:eth_price].to_f
                            else
                              EventService.get_total_price_by_decimals(event[:total_price], 18)
                            end
            end


            begin
              EventTransfer.create! do |event_model|
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
          Rails.logger.info("Event Transfer was not save: #{e.message}")
        end
      end
    end
    duplicate_count
  end

  def self.save_event opensea_response
    duplicate_count = 0

    if (!opensea_response.nil?) && opensea_response[:asset_events].length > 0
      opensea_response[:asset_events].each do |event|
        next unless event[:asset].present?

        begin
          unless Event.find_by_id(event[:id])
            if check_event_details(event)
              seller_account_id = Account.update_or_create_by_address(
                event[:seller][:address],
                event[:seller][:user] ? event[:seller][:user][:username] : nil,
                event[:seller][:profile_img_url] ? event[:seller][:profile_img_url] : ""
              )

              from_account_id = Account.update_or_create_by_address(
                event[:transaction][:from_account][:address],
                event[:transaction][:from_account][:user] ? event[:transaction][:from_account][:user][:username] : nil,
                event[:transaction][:from_account][:profile_img_url] ? event[:transaction][:from_account][:profile_img_url] : ""
              )

              to_account_id = Account.update_or_create_by_address(
                event[:transaction][:to_account][:address],
                event[:transaction][:to_account][:user] ? event[:transaction][:to_account][:user][:username] : nil,
                event[:transaction][:to_account][:profile_img_url] ? event[:transaction][:to_account][:profile_img_url] : ""
              )

              winner_account_id = Account.update_or_create_by_address(
                event[:winner_account][:address],
                event[:winner_account][:user] ? event[:winner_account][:user][:username] : nil,
                event[:winner_account][:profile_img_url] ? event[:winner_account][:profile_img_url] : ""
              )

              collection_id = Collection.update_or_create_by(event[:asset][:collection])
              asset_id = Asset.update_or_create_by_id(event[:asset], collection_id)

              payment_symbol = 'eth'
              payment_symbol = 'klaytn' if event[:asset][:permalink].include?('klaytn')
              payment_symbol = 'matic' if event[:asset][:permalink].include?('matic')

              total_price = if payment_symbol == 'eth' && event[:payment_token] && event[:payment_token][:symbol] != "ETH" && event[:payment_token][:symbol] != "WETH"
                               EventService.get_total_price_by_decimals(event[:total_price], event[:payment_token][:decimals]) * event[:payment_token][:eth_price].to_f
                            else
                               EventService.get_total_price_by_decimals(event[:total_price], 18)
                            end
              begin
                Event.create! do |event_model|
                  event_model.id = event[:id]
                  event_model.created_date = DateTime.parse(event[:created_date]).utc
                  event_model.quantity = event[:quantity]
                  event_model.total_price = total_price
                  event_model.payment_symbol = payment_symbol
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
            end
          else
            duplicate_count += 1
          end
        rescue Exception => e
          Rails.logger.info("Event was not save: #{e.message}")
        end
      end
    end
    duplicate_count
  end

  def self.check_event_details(event)
    !event[:transaction][:to_account].nil?   &&
    !event[:transaction][:from_account].nil? &&
    !event[:winner_account].nil?             &&
    !event[:seller].nil?
  end

end

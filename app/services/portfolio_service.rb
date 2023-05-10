class PortfolioService

  def self.for_gallery_from_opensea(address, cursor = nil, analysis = false, limit = 18)
    ids = []
    opensea = OpenSea.new()
    res = opensea.retrieving_assets({owner: address, limit: limit, cursor: cursor})
    puts res
    clear_items = res[:assets].map do |item|
      ids.push(item[:id])
      temp_item = {}
      temp_item[:asset_id] = item[:id]
      temp_item[:name] = item[:name]
      temp_item[:url] = item[:permalink]
      temp_item[:image_url] = item[:image_url]
      temp_item[:animation_url] = item[:animation_url]
      temp_item[:contract_address] = item[:asset_contract][:address]
      temp_item[:token_id] = item[:token_id]
      temp_item[:floor_price] = nil
      temp_item[:transaction_hash] = nil
      temp_item[:purchase_date] = nil
        # get_info_about_last_sale(item[:last_sale]) if  item[:last_sale].present?
      temp_item
    end
    if ids.length > 0 && analysis == false
      t = get_floor_price_for_nft(ids.join(","))
      clear_items.each do |elem|
        elem[:floor_price] = t.to_a.find{|item|  item['asset_id'] == elem[:id] }
      end
    end
    {cursor_next: res[:next], cursor_previous: res[:previous], assets: clear_items }
  end

  def self.for_gallery(user_id, page, order_by, sort_by, cursor = nil)
    limit = 18
    offset = page > 1 ? page *  limit - limit : 0
    user = User.find user_id
    account = Account.find_by_address(user.wallet_address)
    if user.owned_assets_is_updating && !(user.owned_assets.count > 0)
      for_gallery_from_opensea(user.wallet_address, cursor, false, 18)
    else
      owned_assets_ids = user.owned_assets.map{|as| as.asset_id}
      assets = owned_assets_ids.length > 0 && account.present? ?
        sql_for_gallery(owned_assets_ids.join(','), account.id, order_by, sort_by, limit, offset) : []
      { assets: assets }
    end

  end

  def self.get_info_about_last_sale(last_sale)
    if last_sale[:payment_token] && last_sale[:payment_token][:symbol] != "ETH" && last_sale[:payment_token][:symbol] != "WETH"
      EventService.get_total_price_by_decimals(last_sale[:total_price], last_sale[:payment_token][:decimals]) * last_sale[:payment_token][:eth_price].to_f
    else
      EventService.get_total_price_by_decimals(last_sale[:total_price], 18)
    end
  end

  def self.get_floor_price_for_nft(ids)
    Event.connection.select_all(
      <<-SQL
        SELECT asset_id, MIN(total_price) AS floor_price
        FROM events
        WHERE asset_id IN (#{ids})
        GROUP BY asset_id
      SQL
    )
  end

  def self.download_owned_asset_to_user(user_id)
    begin
      user = User.find(user_id)
      user.update({owned_assets_is_updating: true, owned_assets_is_updating_time: DateTime.now})
      address = user.wallet_address
      opensea = OpenSea.new()

      owned_assets = opensea.get_all_assets_by_address_owner(address)

      owned_assets_in_db = user.owned_assets.where(date_of_sale: nil).all
      sold_assets = owned_assets_in_db.filter_map{|i| i unless owned_assets.find{|t| t[:id] == i.asset_id}.present?}
      new_assets = owned_assets.filter_map{|i| i unless owned_assets_in_db.find{|t| t.asset_id == i[:id]}.present?}

      new_assets.each do |new_asset|
        collection_id = Collection.update_or_create_by(new_asset[:collection])
        asset_id = Asset.update_or_create_by_id(new_asset, collection_id)
        user.owned_assets.create!({asset_id: asset_id})
      end

      account = Account.find_by_address(address)

      sold_assets.each do |sold_asset|
        event_sale = Event.where(asset_id: sold_asset.asset_id, seller_account_id: account.id).maximum(:created_date)
        event_transfer = EventTransfer.where(asset_id: sold_asset.asset_id, from_account_id: account.id).maximum(:created_date)

        sold_asset.date_of_sale = event_sale.present? ? event_sale : event_transfer || nil
        sold_asset.save
      end if account.present?

      user.owned_assets.where(purchase_date: nil).each do |asset|
        purchase_info = Event.where(asset_id: asset.asset_id, winner_account_id: account.id).to_a.last
        purchase_info = EventTransfer.where(asset_id: asset.asset_id, from_account_id: account.id).to_a.last unless purchase_info.present?


        asset.purchase_date = purchase_info.created_date unless purchase_info.nil?
        asset.purchase_price_eth = purchase_info.total_price unless purchase_info.nil?
        asset.save
      end  if account.present?

      PullingEventsByType.perform_later(DateTime.now.utc.to_i,'successful', user_id)
      PullingEventsByType.perform_later(DateTime.now.utc.to_i,'transfer', user_id)

      user.update({owned_assets_is_updating: false, owned_assets_is_updating_time: nil})
    rescue Exception => e
      Rails.logger.info "Download Owned Assets Error: #{e.message}"
      user.update({owned_assets_is_updating: false, owned_assets_is_updating_time: nil})
    end
  end


  def self.for_analyser(offset, owned_asset_ids, account_id, order_by = "contract_date", sort_by = "DESC", user_id = nil)

    result = sql_asset_information(owned_asset_ids, account_id, offset, order_by, sort_by, user_id)

    usd_currency = EventService.get_crypto_price
    ethers = Etherscan.new()
    result.to_a.each do |asset|

      asset['purchase_gas'] = if asset['transaction_hash'].present?
                                begin
                                gas = ethers.get_gas_by_hash(asset['transaction_hash'])
                                (gas[:result][:gas].hex * gas[:result][:gasPrice].hex * 10.pow(-18)).to_f
                                rescue Exception => e
                                  nil
                                end
                              else
                                nil
                              end

      asset['floor_price_ytd_usd'] = asset['floor_price_ytd'].to_f * usd_currency['ETH']['USD']
      asset['floor_price_one_day_usd'] = asset['floor_price_one_day'].to_f * usd_currency['ETH']['USD']
      asset['purchase_price_usd'] = asset['purchase_price'].to_f * usd_currency['ETH']['USD']
      asset['profit_loss'] = -1 * (asset['purchase_price'].to_f - asset['floor_price_asset'].to_f)
      asset['profit_loss_usd'] =  asset['profit_loss'] * usd_currency['ETH']['USD']
      # purchase_date_usd = Cryptocompare::PriceHistorical.find('ETH', 'USD', {ts: asset['purchase_date'].to_i, api_key: ENV['CRYPTOCOMPARE_KEY'] || '4da8748d1a152d54002d877881a044b896cf912b494273bd6e36b64263793701' })
      # asset['holdings_usd'] = asset['holdings'].to_f * usd_currency['ETH']['USD']
      # puts asset['floor_price']
      # asset['profit_loss_percent'] = (purchase_date_usd['ETH']['USD'] * asset['purchase_price'].to_f) / (usd_currency['ETH']['USD'] * asset['purchase_price'].to_f ) * 100 - 100
      # asset['profit_loss_percent'] = (asset['floor_price'].to_f / asset['purchase_price'].to_f)  * 100 - 100
    end
    # str_to_opensea = result.to_a.map{|tok| "token_ids=#{tok['token_id']}&asset_contract_addresses=#{tok['contract_address']}"}.join('&')
    # json_opensea = opensea.retrieving_assets_by_owner_and_ids(result.to_a.map{|tok| "token_ids=#{tok['token_id']}&asset_contract_addresses=#{tok['contract_address']}"}.join('&'))
    # json_opensea = opensea.retrieving_assets_by_owner_and_ids("token_ids=898&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2478&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2512&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2609&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2610&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=4573&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=5742&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=5892&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=7061&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=7449&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568")
    # puts json_opensea
    #
    # "token_ids=898&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2478&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2512&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2609&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=2610&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=4573&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=5742&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=5892&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=7061&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568&token_ids=7449&asset_contract_addresses=0x701a038af4bd0fc9b69a829ddcb2f61185a49568"
  end

  def self.for_global_page(user_id)
    user = User.find user_id

    if !Rails.env.development? && (user.owned_assets_is_updating_time.nil? || user.owned_assets_is_updating_time + 20.minutes < DateTime.now )
      DownloadOwnedAssetsJob.perform_later(user_id)
    end

    account = Account.find_by_address(user.wallet_address)
    owned_assets = user.owned_assets.where("date_of_sale IS NULL OR date_of_sale >= TO_TIMESTAMP('#{DateTime.now.utc - 30.days}', 'YYYY-MM-DD HH24:MI:SS')")
    owned_assets_ids = owned_assets.map{|item| item.asset_id}
    count_nfts = owned_assets.count
    count_collections = owned_assets_ids.length > 0 ? OwnedAsset.count_collections(owned_assets_ids) : 0
    holdings = owned_assets_ids.length > 0 && account.present? ? OwnedAsset.all_holdings(owned_assets_ids, account.id) : 0.0

    usd_currency = EventService.get_crypto_price
    holdings_uds = usd_currency['ETH']['USD'] * holdings.to_f

    {
      count_nfts: count_nfts,
      count_collections: count_collections,
      holdings: holdings,
      holdings_uds: holdings_uds,
      # date_for_graph: sql_for_global_graph(user_id, DateTime.now.utc)
    }
  end

  def self.individual_page_asset(contract_address = "0x07e5ce0f8fa46031a1dcc8cb2530f0a52019830d", token_id = "1114", address = "0x33a92621c9b45329bb4ff1d5ee14eb15cf2e4638")
    asset = Asset.where(contract_address: contract_address, token_id: token_id).last
    account = Account.find_by_address(address)

    result = for_analyser(0, [asset.id], account.id)
    @open_sea = OpenSea.new()
    from_opensea = @open_sea.retrieving_assets_by_owner_and_ids("token_ids=#{asset.token_id}&asset_contract_addresses=#{asset.contract_address}")
    traits = from_opensea[:assets][0][:traits]
    result[0]['traits'] = traits
    result[0]['collection_name'] = from_opensea[:assets][0][:collection][:name]
    result[0]['asset_name'] = from_opensea[:assets][0][:name]
    result[0]['permalink'] = from_opensea[:assets][0][:permalink]
    result[0]
  end

  def self.sql_asset_information(owned_asset_ids, account_id, offset, order_by = "contract_date", sort_by = "DESC", user_id = nil)
    time_now = DateTime.now.utc
    floor_price_ytd_time = DateTime.new(time_now.year,1,1).utc
    floor_price_one_temp_day =  DateTime.parse(Date.today.to_s).utc
    floor_price_one_temp_day_perc = floor_price_one_temp_day - 1.day
    floor_price_seven_days_ago = floor_price_one_temp_day - 7.days


    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TEMP TABLE temp_table ON COMMIT DROP AS
        SELECT id AS asset_id, image_url AS asset_image, contract_address, token_id, collection_id, url AS asset_url, name AS asset_name, contract_date
          FROM assets
          WHERE assets.id IN (#{owned_asset_ids.join(',')});
  
        CREATE TEMP TABLE floor_price_one_day ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price_one_day, collection_id
          FROM events
          WHERE created_date >= TO_TIMESTAMP('#{floor_price_one_temp_day}', 'YYYY-MM-DD HH24:MI:SS') AND collection_id IN (SELECT collection_id FROM temp_table) 
          GROUP BY collection_id;

        CREATE TEMP TABLE events_asset_id ON COMMIT DROP AS
        SELECT created_date AS purchase_date, MIN(total_price) AS purchase_price, asset_id, transaction_hash
          FROM events
          WHERE winner_account_id = #{account_id} AND asset_id IN (SELECT asset_id FROM temp_table)
          GROUP BY created_date, asset_id, transaction_hash;

        CREATE TEMP TABLE root_table ON COMMIT DROP AS
        SELECT temp_table.asset_id, asset_image, contract_address, token_id, 
               temp_table.collection_id, asset_url, asset_name, contract_date,
               purchase_date, purchase_price, transaction_hash,
                ((CASE
                 WHEN floor_price_one_day IS NULL THEN 0.0
                 WHEN floor_price_one_day IS NOT NULL THEN floor_price_one_day
               END ))  AS floor_price_one_day
        FROM temp_table
        LEFT JOIN floor_price_one_day ON temp_table.collection_id = floor_price_one_day.collection_id
        LEFT JOIN
          (SELECT * FROM events_asset_id
           UNION
           SELECT created_date AS purschase_date, MIN(total_price) AS purchase_price, asset_id, transaction_hash
             FROM event_transfers
             WHERE to_account_id = #{account_id} AND asset_id IN (SELECT asset_id FROM temp_table) AND asset_id NOT IN (SELECT asset_id FROM events_asset_id)
             GROUP BY created_date, asset_id, transaction_hash) purchased ON purchased.asset_id = temp_table.asset_id
        ORDER BY #{order_by} #{sort_by}
        LIMIT 10 OFFSET #{offset};

        CREATE TEMP TABLE collection_id_count ON COMMIT DROP AS
        SELECT collection_id AS id, count(collection_id) AS count_assets
          FROM temp_table
          GROUP BY collection_id;

        CREATE TEMP TABLE floor_price_ytd ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price_ytd, collection_id
          FROM events
          WHERE created_date > TO_TIMESTAMP('#{floor_price_ytd_time}', 'YYYY-MM-DD HH24:MI:SS') AND collection_id IN (SELECT collection_id FROM root_table) 
          GROUP BY collection_id;
  
        CREATE TEMP TABLE floor_price_seven_days_ago ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price_seven_days_ago, collection_id
          FROM events
          WHERE created_date BETWEEN TO_TIMESTAMP('#{floor_price_seven_days_ago}', 'YYYY-MM-DD HH24:MI:SS') AND TO_TIMESTAMP('#{floor_price_seven_days_ago + 1.day}', 'YYYY-MM-DD HH24:MI:SS') AND collection_id IN (SELECT collection_id FROM root_table)
          GROUP BY collection_id;
  
        CREATE TEMP TABLE floor_price_one_previous_day ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price_one_day, collection_id
          FROM events
          WHERE created_date BETWEEN TO_TIMESTAMP('#{floor_price_one_temp_day}', 'YYYY-MM-DD HH24:MI:SS') AND TO_TIMESTAMP('#{floor_price_one_temp_day_perc}', 'YYYY-MM-DD HH24:MI:SS') AND collection_id IN (SELECT collection_id FROM root_table)
          GROUP BY collection_id;
  
        CREATE TEMP TABLE floor_price_one_day_perc ON COMMIT DROP AS
        SELECT (root_table.floor_price_one_day / floor_price_one_previous_day.floor_price_one_day * 100 - 100) AS floor_price_one_day_perc, root_table.collection_id
          FROM root_table
          JOIN  floor_price_one_previous_day ON floor_price_one_previous_day.collection_id = root_table.collection_id;
        
        CREATE TEMP TABLE floor_price_asset_db ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price_asset, asset_id
          FROM events
          WHERE asset_id IN (SELECT asset_id FROM root_table)
          GROUP BY asset_id;

        SELECT root_table.asset_id, asset_image, contract_address, token_id,
               slug, root_table.collection_id, count_assets, purchase_date,
               purchase_price, transaction_hash, floor_price_ytd,
               floor_price_one_day, floor_price_one_day_perc,
               collections.name AS collection_name, asset_url,
               asset_name, floor_price_seven_days_ago, contract_date, 
               floor_price_asset,
              ((CASE
                 WHEN purchase_price IS NULL THEN CASE WHEN floor_price_one_day IS NULL THEN  0 WHEN floor_price_one_day IS NOT NULL THEN 100 END
                 WHEN purchase_price IS NOT NULL THEN (floor_price_one_day / purchase_price) * 100 - 100
               END )) AS profit_loss_percent
        FROM root_table
        LEFT JOIN collection_id_count ON root_table.collection_id = collection_id_count.id
        LEFT JOIN collections ON root_table.collection_id = collections.id
        LEFT JOIN floor_price_ytd ON root_table.collection_id = floor_price_ytd.collection_id
        LEFT JOIN floor_price_one_day_perc ON root_table.collection_id = floor_price_one_day_perc.collection_id
        LEFT JOIN floor_price_seven_days_ago ON root_table.collection_id = floor_price_seven_days_ago.collection_id
        LEFT JOIN floor_price_asset_db ON root_table.asset_id = floor_price_asset_db.asset_id
        ORDER BY #{order_by} #{sort_by}
      SQL
    )
  end

  def self.sql_for_gallery(ids, winner_account_id, order_by = 'floor_price', sort_by = 'ASC', limit = 18, offset = 0)
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TEMP TABLE temp_table ON COMMIT DROP AS
          SELECT id AS asset_id, image_url, contract_address, token_id, url, name, animation_url
            FROM assets
            WHERE assets.id IN(#{ids});

        CREATE TEMP TABLE floor_price ON COMMIT DROP AS
          SELECT MIN(total_price) AS floor_price, asset_id
            FROM events
            WHERE asset_id IN (SELECT asset_id FROM temp_table)
            GROUP BY asset_id;

        CREATE TEMP TABLE purchase_info ON COMMIT DROP AS
          SELECT created_date AS purchase_date, asset_id, transaction_hash
            FROM events
            WHERE winner_account_id = #{winner_account_id} AND asset_id IN (SELECT asset_id FROM temp_table) 
            GROUP BY created_date, asset_id, transaction_hash;

        CREATE TEMP TABLE purchase_info_transfer ON COMMIT DROP AS
        SELECT created_date AS purschase_date, asset_id, transaction_hash
          FROM event_transfers
          WHERE to_account_id = #{winner_account_id} AND asset_id IN (SELECT asset_id FROM temp_table) AND asset_id NOT IN (SELECT asset_id FROM purchase_info)
          GROUP BY created_date, asset_id, transaction_hash;

        SELECT temp_table.asset_id, image_url,
               contract_address, token_id, url,
               name, animation_url, floor_price,
               purchase_date, transaction_hash
        FROM temp_table
        LEFT JOIN floor_price ON temp_table.asset_id = floor_price.asset_id
        LEFT JOIN (SELECT * FROM purchase_info UNION SELECT * FROM purchase_info_transfer) purchase ON purchase.asset_id = temp_table.asset_id
        ORDER BY #{order_by} #{sort_by}
        LIMIT #{limit} OFFSET #{offset};
      SQL
    )
  end


  def self.sql_for_global_graph(user_id, time_now)
    ActiveRecord::Base.connection.execute(
    <<-SQL
      CREATE TEMP TABLE temp_owned_assets ON COMMIT DROP AS
        SELECT *
        FROM owned_assets
        WHERE user_id = #{user_id} AND (date_of_sale IS NULL OR date_of_sale >= TO_TIMESTAMP('#{time_now - 30.days}', 'YYYY-MM-DD HH24:MI:SS'));
  
      CREATE TEMP TABLE temp_floor_price ON COMMIT DROP AS
        SELECT MIN(total_price) AS floor_price, events.asset_id, created_date, purchase_price_eth
        FROM events
        LEFT JOIN temp_owned_assets ON events.asset_id = temp_owned_assets.asset_id
        WHERE events.asset_id IN (SELECT asset_id FROM temp_owned_assets) AND created_date BETWEEN TO_TIMESTAMP('#{time_now - 30.days}', 'YYYY-MM-DD HH24:MI:SS') AND TO_TIMESTAMP('#{time_now}', 'YYYY-MM-DD HH24:MI:SS')
        GROUP BY events.asset_id, created_date, purchase_price_eth;
  
      SELECT time_bucket('1d', created_date) AS time, SUM(-1 * (COALESCE(purchase_price_eth, 0.0) - floor_price)) AS point
        FROM temp_floor_price
        GROUP BY time
        ORDER BY time
    SQL
    )
  end
end

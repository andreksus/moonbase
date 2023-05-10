class EventService
  @@ten_powers = {}

  def self.generate_time_ago(datetime_now, time)
    case time
      when "1m"
        datetime_now - 1.minute
      when "5m"
        datetime_now - 5.minute
      when "10m"
        datetime_now - 10.minute
      when "30m"
        datetime_now - 30.minute
      when "1h"
        datetime_now - 1.hour
      when "12h"
        datetime_now - 12.hour
      when "1d"
        datetime_now - 1.day
      when "3d"
        datetime_now - 3.day
      else
        datetime_now - 10.minute
    end
  end

  def self.get_activity_single_collection(limit, offset, collection_id, payment_symbol= "eth")
    <<-SQL
       SELECT * FROM (SELECT total_price, winner_account_id, seller_account_id, created_date, asset_id
                      FROM events
                      WHERE collection_id = #{collection_id} AND payment_symbol = '#{payment_symbol}'
                      ORDER BY created_date DESC
                      LIMIT #{limit} OFFSET #{offset}) t1
       JOIN (SELECT id, address AS address_winner, name AS winner_account_name
             FROM accounts) winners
             ON t1.winner_account_id = winners.id
       JOIN (SELECT id, address AS address_seller, name AS seller_account_name
             FROM accounts) sellers
             ON t1.seller_account_id = sellers.id
       JOIN (SELECT
                id,
                url AS asset_url,
                token_id AS asset_token_id,
                contract_address AS asset_contract_address
                FROM assets) t_asset
              ON t_asset.id = t1.asset_id
    SQL
  end

  def self.get_transactions_by_ids(ids, limit, offset)
    <<-SQL
       SELECT * FROM(SELECT * ,
                        CASE WHEN winner_account_id IN (#{ids}) THEN 'Buy'
                             WHEN seller_account_id IN (#{ids}) THEN 'Sale'
                        END AS type_transaction
                     FROM events
                     WHERE winner_account_id IN (#{ids}) OR seller_account_id IN (#{ids})
                     ORDER BY created_date DESC
                     LIMIT #{limit} OFFSET #{offset}) t1
       JOIN (SELECT id, address AS address_person, name
             FROM accounts
             WHERE id IN (#{ids})) t2
             ON t1.winner_account_id = t2.id OR t1.seller_account_id = t2.id
       JOIN (SELECT id, address AS address_from FROM accounts) t_from
             ON t_from.id = t1.from_account_id
       JOIN (SELECT id, address AS address_to FROM accounts) t_to
             ON t_to.id = t1.to_account_id
       JOIN (SELECT
                id,
                url AS asset_url,
                token_id AS asset_token_id,
                contract_address AS asset_contract_address
                FROM assets) t_asset
              ON t_asset.id = t1.asset_id
    SQL
  end

  def self.get_top_transactions_by_sql(time_ago, sort_by, sort_type, limit, offset, ids, payment_symbol= "eth")
    <<-SQL
      SELECT *
        FROM (SELECT * ,
                  CASE WHEN winner_account_id IN (#{ids}) THEN 'Buy'
                       WHEN seller_account_id IN (#{ids}) THEN 'Sale'
                  END AS type_transaction
               FROM events
               WHERE winner_account_id IN (#{ids}) OR seller_account_id IN (#{ids}) AND created_date >= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS') AND payment_symbol = '#{payment_symbol}'
               ORDER BY #{sort_by} #{sort_type}
               LIMIT #{limit} OFFSET #{offset}) t1
               JOIN (SELECT id, address AS address_person, name
                   FROM accounts
                         WHERE id IN (#{ids})) t2
                         ON t1.winner_account_id = t2.id OR t1.seller_account_id = t2.id
                   JOIN (SELECT id, address AS address_from FROM accounts) t_from
                         ON t_from.id = t1.from_account_id
                   JOIN (SELECT id, address AS address_to FROM accounts) t_to
                         ON t_to.id = t1.to_account_id
                   JOIN (SELECT
                            id,
                            url AS asset_url,
                            token_id AS asset_token_id,
                            contract_address AS asset_contract_address
                            FROM assets) t_asset
                          ON t_asset.id = t1.asset_id
               ORDER BY #{sort_by} #{sort_type}
      SQL
  end

  def self.trending_collections_by_time_sql(time_ago, sort_by, sort_type, limit, offset, payment_symbol)
    # if time_ago != '1m'
      <<-SQL
        SELECT floor_price, average_price, volume, sales, collection_id, slug, name, image_url, large_image_url, discord_url, telegram_url, twitter_username, instagram_username, payment_symbol
        FROM (SELECT MIN(total_price) AS floor_price,
                    AVG(total_price) AS average_price,
                    SUM(total_price) AS volume,
                    SUM(quantity) AS sales,
                    collection_id,
                    payment_symbol
             FROM events
             WHERE created_date >= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS') AND payment_symbol = '#{payment_symbol}'
             GROUP BY collection_id, payment_symbol
             ORDER BY #{sort_by} #{sort_type}
             LIMIT #{limit} OFFSET #{offset}) t1
        JOIN (SELECT *
              FROM collections) t2
        ON t1.collection_id = t2.id
        ORDER BY #{sort_by} #{sort_type}
      SQL
    # else self.trending_collections_by_time_sql_from_item_sales(time_ago, sort_by, sort_type, limit, offset)
    # end
  end
  # def self.trending_collections_by_time_sql_from_item_sales(time_ago, sort_by, sort_type, limit, offset)
  #   <<-SQL
  #     SELECT floor_price, average_price, volume, sales, collection_id, slug, name, image_url, large_image_url, discord_url, telegram_url, twitter_username, instagram_username, payment_symbol
  #     FROM (SELECT MIN(sale_price) AS floor_price,
  #                 AVG(sale_price) AS average_price,
  #                 SUM(sale_price) AS volume,
  #                 SUM(quantity) AS sales,
  #                 collection_id,
  #                 payment_token AS payment_symbol
  #          FROM item_sales
  #          WHERE created_date >= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS')
  #          GROUP BY collection_id, payment_symbol
  #          ORDER BY #{sort_by} #{sort_type}
  #          LIMIT #{limit} OFFSET #{offset}) t1
  #     JOIN (SELECT *
  #           FROM collections) t2
  #     ON t1.collection_id = t2.id
  #     ORDER BY #{sort_by} #{sort_type}
  #   SQL
  # end

  def self.saved_collections_by_time_sql(time_ago, sort_by, sort_type, limit, offset, payment_symbol, saved_collection_ids)
    <<-SQL
       SELECT floor_price, average_price, volume, sales, collection_id, slug, name, image_url, large_image_url, discord_url, telegram_url, twitter_username, instagram_username, payment_symbol
       FROM (SELECT MIN(total_price) AS floor_price,
                    AVG(total_price) AS average_price,
                    SUM(total_price) AS volume,
                    SUM(quantity) AS sales,
                    collection_id,
                    payment_symbol
             FROM events
             WHERE collection_id IN (#{saved_collection_ids}) AND created_date >= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS') AND payment_symbol = '#{payment_symbol}'
             GROUP BY collection_id, payment_symbol
             ORDER BY #{sort_by} #{sort_type}
             LIMIT #{limit} OFFSET #{offset}) t1
        JOIN (SELECT *
              FROM collections
              WHERE id IN (#{saved_collection_ids})) t2
        ON t1.collection_id = t2.id
        ORDER BY #{sort_by} #{sort_type}
     SQL
  end

  def self.trending_collections_data_for_percent_sql(trending_collection_ids, time_ago, twice_time_ago)
    <<-SQL
       SELECT MIN(total_price) AS floor_price,
              AVG(total_price) AS average_price,
              SUM(total_price) AS volume,
              SUM(quantity) AS sales,
              collection_id
       FROM events
       WHERE collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{twice_time_ago}', 'YYYY-MM-DD HH24:MI:SS')
       GROUP BY collection_id
    SQL
  end

  def self.trending_collections_7d_volume_sql(trending_collection_ids, time_1day_ago, time_2day_ago, time_3day_ago, time_4day_ago, time_5day_ago, time_6day_ago, time_7day_ago)
    <<-SQL
       SELECT t1.id AS collection_id, volume_1d, volume_2d, volume_3d, volume_4d, volume_5d, volume_6d, volume_7d, count
       FROM (SELECT id
             FROM collections
             WHERE id IN (#{trending_collection_ids})) t1
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_1d
                        FROM events
                        WHERE collection_id IN (#{trending_collection_ids}) AND created_date >= TO_TIMESTAMP('#{time_1day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t2
       ON t1.id = t2.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_2d
                        FROM events
                        WHERE collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_1day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_2day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t3
       ON t1.id = t3.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_3d
                        FROM events
                        WHERE collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_2day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_3day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t4
       ON t1.id = t4.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_4d
                        FROM events
                        WHERE events.collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_3day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_4day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t5
       ON t1.id = t5.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_5d
                        FROM events
                        WHERE events.collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_4day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_5day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t6
       ON t1.id = t6.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_6d
                        FROM events
                        WHERE events.collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_5day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_6day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t7
       ON t1.id = t7.collection_id
       FULL OUTER JOIN (SELECT collection_id, SUM(total_price) AS volume_7d
                        FROM events
                        WHERE collection_id IN (#{trending_collection_ids}) AND created_date <= TO_TIMESTAMP('#{time_6day_ago}', 'YYYY-MM-DD HH24:MI:SS') AND created_date >= TO_TIMESTAMP('#{time_7day_ago}', 'YYYY-MM-DD HH24:MI:SS')
                        GROUP BY collection_id) t8
       ON t1.id = t8.collection_id
       FULL OUTER JOIN (SELECT collection_id, COUNT(*) AS count
                        FROM saved_collections
                        WHERE collection_id IN (#{trending_collection_ids})
                        GROUP BY collection_id) t9
       ON t1.id = t9.collection_id
    SQL
  end

  def self.saved_collections_by_trending_ids_sql (user_id, trending_collection_ids)
    <<-SQL
      SELECT id, collection_id
      FROM saved_collections
      WHERE user_id = #{user_id} AND collection_id IN (#{trending_collection_ids})
    SQL
  end

  def self.get_collection_volumes_sql(end_date, interval, collection_id)
    <<-SQL
      SELECT time_bucket('#{interval}', created_date) AS time,
            SUM(total_price) AS volume,
            SUM(quantity) AS sales
      FROM events
      WHERE collection_id = #{collection_id} AND created_date >= TO_TIMESTAMP('#{end_date}', 'YYYY-MM-DD HH24:MI:SS')
      GROUP BY collection_id, time
      ORDER BY time
    SQL
  end

  def self.get_collection_sales_sql(end_date, collection_id)
    <<-SQL
      SELECT total_price, created_date AS time, quantity
      FROM events
      WHERE collection_id = #{collection_id} AND created_date >= TO_TIMESTAMP('#{end_date}', 'YYYY-MM-DD HH24:MI:SS')
      ORDER BY time
    SQL
  end

  def self.get_single_collection_sql(user_id, collection_id, datetime_1_day_ago)
    <<-SQL
      SELECT
          id,
          slug,
          name,
          description,
          payout_address,
          external_url,
          large_image_url,
          image_url,
          discord_url,
          telegram_url,
          twitter_username,
          instagram_username,
          count_of_tracking,
          saved_in_db,
          saved_collection_id,
          average_price_24h,
          volume_24h,
          sales_24h,
          payment_symbol
      FROM (SELECT
            id,
            slug,
            name,
            description,
            payout_address,
            external_url,
            large_image_url,
            image_url,
            discord_url,
            telegram_url,
            twitter_username,
            instagram_username,
            (SELECT COUNT (*) FROM saved_collections WHERE collection_id = #{collection_id}) AS count_of_tracking,
            (CASE WHEN EXISTS(SELECT * FROM saved_collections WHERE collection_id = #{collection_id} AND user_id = #{user_id}) then 1 else 0 end) AS saved_in_db,
            (CASE WHEN EXISTS(SELECT * FROM saved_collections WHERE collection_id = #{collection_id} AND user_id = #{user_id}) then
                (SELECT id FROM saved_collections WHERE collection_id = #{collection_id} AND user_id = #{user_id}) else 0 end) AS saved_collection_id
            FROM collections
            WHERE id = #{collection_id}) t1
      LEFT JOIN (SELECT AVG(total_price) AS average_price_24h,
                   SUM(total_price) AS volume_24h,
                   SUM(quantity) AS sales_24h,
                   collection_id
            FROM events
            WHERE collection_id = #{collection_id} AND created_date >= TO_TIMESTAMP('#{datetime_1_day_ago}', 'YYYY-MM-DD HH24:MI:SS')
            GROUP BY collection_id) t2
      ON t1.id = t2.collection_id
      JOIN (SELECT DISTINCT collection_id, payment_symbol
            FROM events
            WHERE collection_id = #{collection_id}) t3
      ON t1.id = t3.collection_id
    SQL
  end

  def self.top_10_holders_sql(collection_id)
    <<-SQL
      SELECT winner_account_id as account_id, (quantity_win - (CASE WHEN quantity_sell IS NULL THEN 0 ELSE quantity_sell END)) AS quantity_total
      FROM (SELECT winner_account_id, SUM(quantity) AS quantity_win
           FROM events
           WHERE collection_id = #{collection_id}
           GROUP BY winner_account_id) t1
      LEFT JOIN (SELECT seller_account_id, SUM(quantity) AS quantity_sell
                FROM events
                WHERE collection_id = #{collection_id}
                GROUP BY seller_account_id) t2
      ON t1.winner_account_id = t2.seller_account_id
      ORDER BY quantity_total DESC
      LIMIT 10
    SQL
  end

  def self.top_10_holders_info_sql(account_ids)
    <<-SQL
      SELECT id, name, address
      FROM accounts
      WHERE id IN (#{account_ids})
    SQL
  end

  def self.get_top_10_holders(collection_id)
    top_10_holders = Event.connection.select_all(top_10_holders_sql(collection_id))
    top_10_holders_array = top_10_holders.to_a

    top_10_holders_ids = []

    top_10_holders_array.each do |holder|
      top_10_holders_ids.push(holder["account_id"])
    end


    top_10_holders_ids_db = top_10_holders_ids.join(",")
    top_10_holders_info = Account.connection.select_all(top_10_holders_info_sql(top_10_holders_ids_db))

    top_10_holders_info_hash = {}
    top_10_holders_info.to_a.each do |holder_info|
      top_10_holders_info_hash[holder_info["id"]] = holder_info
    end


    top_10_holders_array.each do |holder|
      holder["name"] = top_10_holders_info_hash[holder["account_id"]]["name"]
      holder["address"] = top_10_holders_info_hash[holder["account_id"]]["address"]
    end

    top_10_holders_array
  end

  def self.add_percent_to_holders(top_10_holders, collection_slug)
    open_sea_instance = OpenSea.new

    collection = open_sea_instance.retrieving_single_collection({:collection_slug => collection_slug})

    total_supply = collection["collection"]["stats"]["total_supply"]

    top_10_holders.each do |holder|
      holder["supply_owned_percent"] = holder["quantity_total"] * 100 / total_supply
    end
  end

  def self.collect_data(trending_collections_by_time_array, data_for_percent, volumes_7d, saved_collections_by_trending_ids_array, crypto_price, volume_dates)
    data_for_percent_hash = {}
    data_for_percent.to_a.each {|collection| data_for_percent_hash[collection["collection_id"]] = collection}

    volumes_7d_hash = {}
    volumes_7d.to_a.each {|collection| volumes_7d_hash[collection["collection_id"]] = collection}

    saved_collections_by_trending_ids_hash = {}
    saved_collections_by_trending_ids_array.each {|collection| saved_collections_by_trending_ids_hash[collection["collection_id"]] = collection}

    eth_to_usd_price = crypto_price["ETH"]["USD"]

    trending_collections_by_time_array.each do |collection|
      collection["volume_dates"] = volume_dates
      collection_for_percent = data_for_percent_hash[collection["collection_id"]]
      collection_7d_volume = volumes_7d_hash[collection["collection_id"]]
      saved_collection = saved_collections_by_trending_ids_hash[collection["collection_id"]]

      if collection_for_percent.present?
        collection_for_percent["floor_price_usd"] = collection_for_percent["floor_price"] * eth_to_usd_price
        collection_for_percent["average_price_usd"] = collection_for_percent["average_price"] * eth_to_usd_price
        collection_for_percent["volume_usd"] = collection_for_percent["volume"] * eth_to_usd_price

        # collection["floor_price_percent"] = collection["floor_price"]["usd"] * 100 / collection_for_percent["floor_price_usd"]
        # collection["average_price_percent"] = collection["average_price"]["usd"] * 100 / collection_for_percent["average_price_usd"]
        # collection["volume_percent"] = collection["volume"]["usd"] * 100 / collection_for_percent["volume_usd"]
        # collection["sales_percent"] = collection["sales"] * 100 / collection_for_percent["sales"]
        # Ваня - я посмотрел и короче если не отнимать 100 то неправильные проценты получаются - Сравнивал с icy.tool - там тоже саме если отнимать 100
        collection["floor_price_percent"] = collection["floor_price"]["usd"] / collection_for_percent["floor_price_usd"] * 100 - 100
        collection["average_price_percent"] = collection["average_price"]["usd"] / collection_for_percent["average_price_usd"] * 100 - 100
        collection["volume_percent"] = collection["volume"]["usd"] / collection_for_percent["volume_usd"] * 100 - 100
        collection["sales_percent"] = collection["sales"] / collection_for_percent["sales"] * 100 - 100

        # collection["floor_price_percent"] = -collection["floor_price_percent"] if collection["floor_price"]["usd"] < collection_for_percent["floor_price_usd"]
        # collection["average_price_percent"] = -collection["average_price_percent"] if collection["average_price"]["usd"] < collection_for_percent["average_price_usd"]
        # collection["volume_percent"] = -collection["volume_percent"] if collection["volume"]["usd"] < collection_for_percent["volume_usd"]
        # collection["sales_percent"] = -collection["sales_percent"] if collection["sales"] < collection_for_percent["sales"]
      else
        collection["floor_price_percent"] = 0.0
        collection["average_price_percent"] = 0.0
        collection["volume_percent"] = 0.0
        collection["sales_percent"] = 0.0
      end

      collection["volume_1d"] = {}
      collection["volume_2d"] = {}
      collection["volume_3d"] = {}
      collection["volume_4d"] = {}
      collection["volume_5d"] = {}
      collection["volume_6d"] = {}
      collection["volume_7d"] = {}

      if collection_7d_volume.present?
        volume_1d = collection_7d_volume["volume_1d"]
        volume_2d = collection_7d_volume["volume_2d"]
        volume_3d = collection_7d_volume["volume_3d"]
        volume_4d = collection_7d_volume["volume_4d"]
        volume_5d = collection_7d_volume["volume_5d"]
        volume_6d = collection_7d_volume["volume_6d"]
        volume_7d = collection_7d_volume["volume_7d"]


        if volume_1d.present?
          collection["volume_1d"]["eth"] = volume_1d
          collection["volume_1d"]["usd"] = volume_1d * eth_to_usd_price
        else
          collection["volume_1d"]["eth"] = 0
          collection["volume_1d"]["usd"] = 0
        end

        if volume_2d.present?
          collection["volume_2d"]["eth"] = volume_2d
          collection["volume_2d"]["usd"] = volume_2d * eth_to_usd_price
        else
          collection["volume_2d"]["eth"] = 0
          collection["volume_2d"]["usd"] = 0
        end

        if volume_3d.present?
          collection["volume_3d"]["eth"] = volume_3d
          collection["volume_3d"]["usd"] = volume_3d * eth_to_usd_price
        else
          collection["volume_3d"]["eth"] = 0
          collection["volume_3d"]["usd"] = 0
        end

        if volume_4d.present?
          collection["volume_4d"]["eth"] = volume_4d
          collection["volume_4d"]["usd"] = volume_4d * eth_to_usd_price
        else
          collection["volume_4d"]["eth"] = 0
          collection["volume_4d"]["usd"] = 0
        end

        if volume_5d.present?
          collection["volume_5d"]["eth"] = volume_5d
          collection["volume_5d"]["usd"] = volume_5d * eth_to_usd_price
        else
          collection["volume_5d"]["eth"] = 0
          collection["volume_5d"]["usd"] = 0
        end

        if volume_6d.present?
          collection["volume_6d"]["eth"] = volume_6d
          collection["volume_6d"]["usd"] = volume_6d * eth_to_usd_price
        else
          collection["volume_6d"]["eth"] = 0
          collection["volume_6d"]["usd"] = 0
        end

        if volume_7d.present?
          collection["volume_7d"]["eth"] = volume_7d
          collection["volume_7d"]["usd"] = volume_7d * eth_to_usd_price
        else
          collection["volume_7d"]["eth"] = 0
          collection["volume_7d"]["usd"] = 0
        end

        collection["count_of_tracking"] = collection_7d_volume["count"].present? ? collection_7d_volume["count"] : 0
      else
        collection["volume_1d"]["usd"] = 0
        collection["volume_2d"]["usd"] = 0
        collection["volume_3d"]["usd"] = 0
        collection["volume_4d"]["usd"] = 0
        collection["volume_5d"]["usd"] = 0
        collection["volume_6d"]["usd"] = 0
        collection["volume_7d"]["usd"] = 0

        collection["volume_1d"]["eth"] = 0
        collection["volume_2d"]["eth"] = 0
        collection["volume_3d"]["eth"] = 0
        collection["volume_4d"]["eth"] = 0
        collection["volume_5d"]["eth"] = 0
        collection["volume_6d"]["eth"] = 0
        collection["volume_7d"]["eth"] = 0

        collection["count_of_tracking"] = 0
      end

      if saved_collection.present?
        collection['saved_in_db'] = true
        collection['id'] = saved_collection["id"]
      else
        collection['saved_in_db'] = false
        collection['id'] = nil
      end

    end
  end

  def self.add_usd_to_collections (trending_collections, crypto_price)
    trending_collections_array = trending_collections.to_a

    trending_collections_array.each do |collection|
      volume_eth = collection["volume"]
      average_price_eth = collection["average_price"]
      floor_price_eth = collection["floor_price"]

      collection["volume"] = {
        "eth" => volume_eth,
        "usd" => volume_eth * crypto_price["ETH"]["USD"]
      }

      collection["average_price"] = {
        "eth" => average_price_eth,
        "usd" => average_price_eth * crypto_price["ETH"]["USD"]
      }

      collection["floor_price"] = {
        "eth" => floor_price_eth,
        "usd" => floor_price_eth * crypto_price["ETH"]["USD"]
      }

    end

    trending_collections_array
  end

  def self.get_crypto_price
    result = Cryptocompare::Price.find(['KLAY', 'MATIC', 'ETH'], ['USD', 'MATIC', 'ETH', 'KLAY'], { api_key: ENV['CRYPTOCOMPARE_KEY'] || '4da8748d1a152d54002d877881a044b896cf912b494273bd6e36b64263793701' })
    $redis.publish("ethereum_price", {eth_price: result}.to_json)
    result
  end

  def self.get_date_by_history(datetime_now, history)
    datetime_by_history = nil

    case history
      when "6 Hours"
      datetime_by_history = datetime_now - 6.hours
      when "12 Hours"
      datetime_by_history = datetime_now - 12.hours
      when "1 Day"
        datetime_by_history = datetime_now - 1.day
      when "3 Days"
        datetime_by_history = datetime_now - 3.day
      when "7 Days"
        datetime_by_history = datetime_now - 7.day
      when "14 Days"
        datetime_by_history = datetime_now - 14.day
      when "30 Days"
        datetime_by_history = datetime_now - 30.day
      when "90 Days"
        datetime_by_history = datetime_now - 90.day
      when "YTD"
        datetime_by_history = DateTime.new(DateTime.now.year, 1, 1)
      else
        datetime_by_history = datetime_now - 1.day
    end

    datetime_by_history
  end

  def self.get_total_price_by_decimals(total_price, decimals)
    new_total_price = nil

    if @@ten_powers[decimals]
      new_total_price = BigDecimal(total_price) / BigDecimal(@@ten_powers[decimals])
    else
      ten_power = 10 ** decimals
      @@ten_powers[decimals] = ten_power

      new_total_price = BigDecimal(total_price) / BigDecimal(ten_power)
    end

    new_total_price.to_f
  end

  private
  def self.save(opensea_response)
    open_sea = OpenSea.new

    duplicate_count = 0

    if opensea_response[:asset_events].length > 0
      opensea_response[:asset_events].each do |event|
        next unless event[:asset].present?

        begin
          seller_account_id = (Account.find_or_create_by(address: event[:seller][:address]) do |account|
            account.name = event[:seller][:user] ? event[:seller][:user][:username] : nil
          end).id

          from_account_id = (Account.find_or_create_by(address: event[:transaction][:from_account][:address]) do |account|
            account.name = event[:transaction][:from_account][:user] ? event[:transaction][:from_account][:user][:username] : nil
          end).id

          to_account_id =  (Account.find_or_create_by(address: event[:transaction][:to_account][:address]) do |account|
            account.name = event[:transaction][:to_account][:user] ? event[:transaction][:to_account][:user][:username] : nil
          end).id

          winner_account_id = (Account.find_or_create_by(address: event[:winner_account][:address]) do |account|
            account.name = event[:winner_account][:user] ? event[:winner_account][:user][:username] : nil
          end).id

          collection_id = (Collection.find_or_create_by(slug: event[:asset][:collection][:slug]) do |collection|
            collection.name = event[:asset][:collection][:name]
            collection.description = event[:asset][:collection][:description]
            collection.image_url = event[:asset][:collection][:image_url]
            collection.large_image_url = event[:asset][:collection][:large_image_url]
            collection.discord_url = event[:asset][:collection][:discord_url]
            collection.telegram_url = event[:asset][:collection][:telegram_url]
            collection.external_url = event[:asset][:collection][:external_url]
            collection.twitter_username = event[:asset][:collection][:twitter_username]
            collection.instagram_username = event[:asset][:collection][:instagram_username]
            collection.payout_address = event[:asset][:collection][:payout_address]
          end).id

          asset_id = (Asset.find_or_create_by(id: event[:asset][:id]) do |asset|
            asset.name = event[:asset][:name]
            asset.description = event[:asset][:description]
            asset.url = event[:asset][:permalink]
            asset.image_url = event[:asset][:image_url]
            asset.contract_date = DateTime.parse(event[:asset][:asset_contract][:created_date]).utc
            asset.collection_id = collection_id
            asset.contract_address = event[:asset][:asset_contract][:address]
            asset.token_id = event[:asset][:token_id]
          end).id

          payment_symbol = 'eth'
          payment_symbol = 'klaytn' if event[:asset][:permalink].include?('klaytn')
          payment_symbol = 'matic' if event[:asset][:permalink].include?('matic')

          total_price = nil

          if payment_symbol == 'eth' && event[:payment_token] && event[:payment_token][:symbol] != "ETH" && event[:payment_token][:symbol] != "WETH"

            total_price = get_total_price_by_decimals(event[:total_price], event[:payment_token][:decimals]) * event[:payment_token][:eth_price].to_f
          else
            total_price = get_total_price_by_decimals(event[:total_price], 18)
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
            end
          rescue
            duplicate_count = duplicate_count + 1
          end

        rescue Exception => e
          Rails.logger.info(e)
        end
      end
    end

    duplicate_count
  end
end

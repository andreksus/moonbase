class TradeService

  def self.trades_by_collection_id_sql(params)
    collection_id = params[:id]
    interval = params[:interval]
    asset_ids = Asset.where(collection_id: collection_id).ids
    get_data_with_sql(0, 0, asset_ids.join(','), interval.to_f)
  end

  def self.get_data_with_sql(min_price, max_price, asset_ids, interval = 0.01)
    date_now = DateTime.parse(Date.today.to_s).utc
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TEMP TABLE sales_temp ON COMMIT DROP AS
            SELECT sale_price
            FROM item_sales
            WHERE asset_id IN (#{asset_ids}) AND created_date >= TO_TIMESTAMP('#{date_now}', 'YYYY-MM-DD HH24:MI:SS');
        do $$
          DECLARE 
              minVariable numeric;
              maxVariable numeric;
          BEGIN
            SELECT CAST(MIN(sale_price) AS numeric)
            INTO minVariable
            FROM sales_temp;

            SELECT CAST(MAX(sale_price) AS numeric)
            INTO maxVariable
            FROM sales_temp;

            CREATE TEMP TABLE series ON COMMIT DROP AS
            SELECT CAST(generate_series as double precision) as _start,
                (CAST(generate_series as double precision) + #{interval} ) as _end
            FROM generate_series(minVariable, maxVariable +  #{interval}, #{interval});

            CREATE TEMP TABLE result_table ON COMMIT DROP AS
            SELECT COUNT(sale_price) as count_prices, CAST(_start as double precision) AS _start FROM series
            JOIN sales_temp ON sales_temp.sale_price >= series._start AND sales_temp.sale_price < series._end
            GROUP BY series._start
            ORDER BY series._start;
          END;
        $$;
      SELECT * FROM result_table;
    SQL
    )
  end

  def self.trending_collections_by_time_sql_from_item_sales(time_ago, sort_by, sort_type, limit, offset)
      <<-SQL
        SELECT floor_price, average_price, volume, sales, collection_id, slug, name, image_url, large_image_url, discord_url, telegram_url, twitter_username, instagram_username, payment_symbol
        FROM (SELECT MIN(sale_price) AS floor_price,
                    AVG(sale_price) AS average_price,
                    SUM(sale_price) AS volume,
                    SUM(quantity) AS sales,
                    collection_id,
                    payment_token AS payment_symbol
             FROM item_sales
             WHERE created_date >= TO_TIMESTAMP('#{time_ago}', 'YYYY-MM-DD HH24:MI:SS')
             GROUP BY collection_id, payment_symbol
             ORDER BY #{sort_by} #{sort_type}
             LIMIT #{limit} OFFSET #{offset}) t1
        JOIN (SELECT *
              FROM collections) t2
        ON t1.collection_id = t2.id
        ORDER BY #{sort_by} #{sort_type}
      SQL
    end


end
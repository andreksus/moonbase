class ListingService

  def self.listings_by_collection_id_sql(params)
    collection_id = params[:id]
    interval = params[:interval]
    asset_ids = Asset.where(collection_id: collection_id).ids
    # listings = Listing.where(asset_id: asset_ids)
    # min_price = listings.minimum(:base_price) || 0.0
    # max_price = listings.maximum(:base_price) || 0.0


    get_data_with_sql(0, 0, asset_ids.join(','), interval.to_f)
  end

  # assets.each do |asss|
  #   if asss.listings.count > 0
  #     need_list = asss.listings.where("created_date = ?", asss.listings.maximum(:created_date) ).last
  #
  #     we = asss.listings.filter{|a| a.id != need_list.id}
  #     we.each{|tem| tem.destroy}
  #   end
  #   ""
  # end

  def self.get_data_with_sql(min_price, max_price, asset_ids, interval = 0.01)
    date_now = DateTime.parse(Date.today.to_s).utc
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TEMP TABLE listings_temp ON COMMIT DROP AS
            SELECT base_price
            FROM listings
            WHERE asset_id IN (#{asset_ids}) AND created_date >= TO_TIMESTAMP('#{date_now}', 'YYYY-MM-DD HH24:MI:SS');
        do $$
          DECLARE 
              minVariable numeric;
              maxVariable numeric;
          BEGIN
            SELECT CAST(MIN(base_price) AS numeric)
            INTO minVariable
            FROM listings_temp;

            SELECT CAST(MAX(base_price) AS numeric)
            INTO maxVariable
            FROM listings_temp;

            CREATE TEMP TABLE series ON COMMIT DROP AS
            SELECT CAST(generate_series as double precision) as _start,
                (CAST(generate_series as double precision) + #{interval} ) as _end
            FROM generate_series(minVariable, maxVariable +  #{interval}, #{interval});

            CREATE TEMP TABLE result_table ON COMMIT DROP AS
            SELECT COUNT(base_price) as count_prices, CAST(_start as double precision) AS _start FROM series
            JOIN listings_temp ON listings_temp.base_price >= series._start AND listings_temp.base_price < series._end
            GROUP BY series._start
            ORDER BY series._start;
          END;
        $$;
      SELECT * FROM result_table;
    SQL
    )

    # ActiveRecord::Base.connection.execute(
    #   <<-SQL
    #     CREATE TEMP TABLE series ON COMMIT DROP AS
    #     SELECT CAST(generate_series as double precision) as _start,
    #         (CAST(generate_series as double precision) + #{interval} ) as _end
    #     FROM generate_series(#{min_price}, #{max_price + interval}, #{interval});
    #
    #     SELECT COUNT(base_price) as count_prices, CAST(_start as double precision) AS _start FROM series
    #     JOIN (SELECT * FROM listings WHERE asset_id IN (#{asset_ids})) t1
    #          ON t1.base_price >= series._start AND t1.base_price < series._end
    #     GROUP BY series._start
    #     ORDER BY series._start
    #   SQL
    # )
  end
end
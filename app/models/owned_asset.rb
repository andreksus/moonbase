class OwnedAsset < ApplicationRecord

  def self.count_collections(owned_asset_ids)
    Asset.connection.select_all(
      <<-SQL
       SELECT collection_id AS id
         FROM assets
         WHERE assets.id IN (#{owned_asset_ids.join(',')})
         GROUP BY collection_id;
      SQL
    ).to_a.length
  end

  def self.all_holdings(owned_asset_ids, account_id)
    Event.connection.select_all(
      <<-SQL
        SELECT SUM(floor_price) AS holdings
        FROM
        (SELECT MIN(total_price) AS floor_price
          FROM events
          WHERE events.asset_id IN (#{owned_asset_ids.join(',')})
          GROUP BY asset_id) t1
      SQL
    ).to_a[0]['holdings']

    # Event.connection.select_all(
    #   <<-SQL
    #     SELECT SUM(total_price) AS holdings
    #       FROM events
    #       WHERE events.asset_id IN (#{owned_asset_ids.join(',')})
    #       AND winner_account_id = #{account_id}
    # SQL
    # ).to_a[0]['holdings']
  end

end

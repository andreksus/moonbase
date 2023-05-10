class SearchService
  def self.global_search_by_query(query)
    collections = Collection.search(query).records.limit(5).select(:id, :name, :image_url)
    # assets      = Asset.search(query).records.limit(5).select(:id, :name, :image_url, :contract_address, :token_id)
    # accounts    = Account.search(query).records.limit(5)

    collections = collections.to_a.map do |col|
      temp_col = col.attributes

      temp_col['count_assets'] = Asset.__elasticsearch__.search(
        "query": {
          "term": {
            "collection_id": col.id
          }
        }
      ).results.total

      temp_col
    end if collections.present?

    {
      collections:     collections
      # assets:          assets,
      # accounts:        accounts
    }
  end

  def self.search_account(query)
    accounts = if Rails.env.production?
                 Account.search(query).records
               else
                 query =~ /0x/i ?
                   Account.search_by_address(query)
                   :
                   Account.search_by_name(query)
               end

    { accounts: accounts }
  end

  def self.check_regex_address(query)
    regex = /(\b0x[a-f0-9]{0,40}\b)/i
    query.match(regex)
  end
end

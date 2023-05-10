require 'uri'
require 'net/http'
require 'openssl'
class OpenSea

    def initialize(api_key = "93121b9e11c54b0c8051b98dc8937685")
        @url = "https://api.opensea.io/api/v1/"
        @api_key = ENV['opensea_api_key'] || api_key
    end

    def response(url, accept = "")
        # Rails.logger.info "API KEY: #{@api_key}"
        retries ||= 0
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request["Accept"] = accept if accept.present?
        request["X-API-KEY"] = @api_key
        # request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
        # request['referrer'] = url

        response = http.request(request)

        raise TimeoutError.new "Error!!! #{response.code}" if response.code.to_i == 429

        if response.code.to_i == 404 || response.code.to_i == 504 || response.code.to_i == 502
            return nil
        else
            return response.body
        end

    rescue TimeoutError => e
        Rails.logger.info "Error message: #{e.message} response: #{response.read_body}"
        Rails.logger.info "Sleep 20 seconds in response block"
        sleep(6 + retries)
        if (retries += 1) < 7
            retry
        end
    end

    def retrieving_listings(token_id, asset_contract_address)
        url = URI(@url + "asset/" + asset_contract_address.to_s + "/" + token_id.to_s + "/" + "listings?limit=50")
        Rails.logger.info "Retrieving Listings URL: #{url}"
        result = response(url, 'application/json')
        json_opensea = JSON.parse(result,  symbolize_names: true) if result.present?
        # Rails.logger.info "Count Retrieved Listings: #{json_opensea[:listings].count + json_opensea[:seaport_listings].count}" if json_opensea.present?
        json_opensea.present? ? json_opensea : nil
    end

    def retrieving_assets(params)
        url = URI(@url + "assets?" + params.compact().to_query())
        JSON.parse(response(url, 'application/json'),  symbolize_names: true)
    end

    def retrieving_assets_by_owner_and_ids(str_query)
        url = URI(@url + "assets?" + str_query)
        # JSON.parse(response(url, 'application/json'),  symbolize_names: true)
        json_opensea = JSON.parse(response(url, 'application/json'),  symbolize_names: true)
        json_opensea.length > 0 ? json_opensea : nil
    end

    def retrieving_events(
      event_type = "successful",
      only_opensea = false,
      limit = 50,
      collection_slug = "",
      token_id= "",
      asset_contract_address = "",
      account_address = "",
      auction_type = "",
      occurred_before = "",
      occurred_after = nil,
      cursor = nil
    )

            query = {
                asset_contract_address: asset_contract_address,
                collection_slug: collection_slug,
                token_id: token_id,
                account_address: account_address,
                event_type: event_type,
                only_opensea: only_opensea,
                auction_type: auction_type,
                limit: limit,
                occurred_before: occurred_before,
                occurred_after: occurred_after,
                cursor: cursor
            }.compact().to_query()

            puts query

        url = URI(@url + "events?" + query)
        result = response(url, 'application/json')

        json_opensea = JSON.parse(result, symbolize_names: true) if result.present?
        json_opensea.present? ? json_opensea : nil
    end

    def retrieving_collections(params)
        url = URI(@url + "collections?" + params.to_query())
        JSON.parse(response(url))
    end

    def retrieving_bundles
        query = {
            owner: owner,
            limit: limit,
            offset: offset,
            on_sale: on_sale,
            token_ids: token_ids,
            asset_contract_address: asset_contract_address,
            asset_contract_addresses: asset_contract_addresses,
        }.compact().to_query()

        url = URI(@url + "bundles?" + query)
        JSON.parse(response(url))
    end

    def retrieving_single_asset(params)
        url = URI(@url + "asset/" + params.asset_contract_address + "/" + params.token_id + "?" + params.account_address)
        JSON.parse(response(url))
    end

    def retrieving_single_contract(asset_contract_address)
        url = URI(@url + "asset_contract/" + asset_contract_address)
        JSON.parse(response(url), symbolize_names: true)
    end

    def retrieving_single_collection(params)
        url = URI(@url + "collection/" + params[:collection_slug])
        JSON.parse(response(url))
    end

    def retrieving_single_collection_sym(params)
        url = URI(@url + "collection/" + params[:collection_slug])
        rsp = response(url)
        if !rsp.nil? 
            JSON.parse(rsp, symbolize_names: true)
        else
            nil
        end
    end

    def retrieving_collection_stats(params)
        url = URI(@url + "collection/" + params[:collection_slug] + "/stats")
        JSON.parse(response(url, 'application/json'), symbolize_names: true)
    end

    def from_wei(amount, unit = 1000000000000000000)
        return nil if amount.nil?
        (BigDecimal(amount, 16) / BigDecimal(unit, 16)).to_s rescue nil
    end

    def self.get_price_to_ucd()
        result = Cryptocompare::Price.find(['KLAY', 'MATIC', 'ETH'], 'USD', { api_key: ENV['CRYPTOCOMPARE_KEY'] || '' })
        $redis.publish("ethereum_price", {eth_price: result}.to_json)
        result
    end

    def get_asset_traits_by_token_ids(args)
        query = ""
        args.each do |arg|
            query += "asset_contract_addresses=#{arg[:asset_contract_address]}&token_ids=#{arg[:token_id]}&"
        end

        json_opensea = JSON.parse(response(URI(@url + "assets?" + query), 'application/json'), symbolize_names: true)
        json_opensea[:assets].map do |item|
            temp = {}
            temp[:asset_contract_address] = item[:asset_contract][:address]
            temp[:token_id] = item[:token_id]
            temp[:traits] = item[:traits]
            temp[:average_trait] = temp[:traits]&.inject(0.0){|sum,e| sum + e[:trait_count] || 0.0 } / temp[:traits].length.to_f / 100.0
            temp[:sum_trait] = temp[:traits]&.inject(0.0){|sum,e| sum + e[:trait_count] } / 100.0
            temp
        end
    end

    def get_all_assets_by_address_owner(address)
        result = []
        temp_res = self.retrieving_assets({owner: address, limit: 50, cursor: nil})
        result += temp_res[:assets]
            while temp_res[:next].present?
                temp_res = retrieving_assets({owner: address, limit: 50, cursor: temp_res[:next]})
                result += temp_res[:assets]
            end
        result
    rescue StandardError => e
        Rails.logger.info "Error in getting assets: #{e.message}"
    end

end

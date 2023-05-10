class AddContractAddressJob < ApplicationJob
    queue_as 'MoonbaseListingsWorker'
    def perform()
        self.class.perform()
    end

    def self.perform()
        open_sea = OpenSea.new
        collections = Collection.where(contract_address: nil)
        puts "Current count to update collections: ", collections.count
        collections.each do |collection|
            # puts collection.slug
            single_collection = open_sea.retrieving_single_collection_sym({:collection_slug => collection.slug})
            if !single_collection.nil?
                if (!single_collection["collection"].nil? && single_collection["collection"]["primary_asset_contracts"].present?)
                    collection.update!(contract_address: single_collection["collection"]["primary_asset_contracts"][0]["address"])
                    puts "Used OpenSea"
                else
                    if a = Asset.find_by(collection_id: collection.id)
                        collection.update!(contract_address: a.contract_address)
                        puts "Used DB"
                    end
                end
                sleep(1.0/2.0)
            else
                if a = Asset.find_by(collection_id: collection.id)
                    collection.update!(contract_address: a.contract_address)
                    puts "Used DB"
                end
            end
        end
    end
end
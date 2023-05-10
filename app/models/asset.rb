class Asset < ApplicationRecord
  has_many :owned_assets
  has_many :listings
  # if ENV["BACKGROUND_WORKER_NUMBER"] == "second"
  #   after_update :start_update_listings
  # end


  if Rails.env.production? && ENV['BACKGROUND_WORKER_NUMBER'] != 'second'
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    def as_indexed_json(_options = {})
      self.as_json(
        only: [:id, :name, :contract_address, :collection_id]
      )
    end
  end

  def start_update_listings
    unless self.url.include?("matic") || self.url.include?("klay")
      # UpdateListingsByAssetId.perform_later(self.token_id, self.id, self.contract_address)
      UpdateListingsByAssetId.perform_later(self.id)
    end
  end

  def self.create_by_asset_id(owned_asset, collection_id)
    (self.find_or_create_by(id: owned_asset[:id]) do |asset|
      asset.name = owned_asset[:name]
      asset.description = owned_asset[:description]
      asset.url = owned_asset[:permalink]
      asset.image_url = owned_asset[:image_url]
      asset.contract_date = DateTime.parse(owned_asset[:asset_contract][:created_date]).utc
      asset.collection_id = collection_id
      asset.contract_address = owned_asset[:asset_contract][:address]
      asset.token_id = owned_asset[:token_id]
      asset.animation_url = owned_asset[:animation_url]
    end).id
  end

  def self.update_or_create_by_id(_obj, collection_id)
    attributes = {
      url:                _obj[:permalink],
      name:               _obj[:name],
      image_url:          _obj[:image_url],
      animation_url:      _obj[:animation_url],
      description:        _obj[:description],
      contract_date:       DateTime.parse(_obj[:asset_contract][:created_date]).utc,
    }

    asset = self.where(contract_address: _obj[:asset_contract][:address], token_id: _obj[:token_id]).first_or_create do |as|
      as.collection_id = collection_id
      as.id = _obj[:id]
      # asset.contract_address = _obj[:asset_contract][:address]
      # asset.token_id = _obj[:token_id]
    end

    asset.update(attributes)
    return asset.id
  end

end

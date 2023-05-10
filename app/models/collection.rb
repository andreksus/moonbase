class Collection < ApplicationRecord

  if Rails.env.production? && ENV['BACKGROUND_WORKER_NUMBER'] != 'second'
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    def as_indexed_json(_options = {})
      self.as_json(
        only: [:id, :name, :slug]
      )
    end
  end

  def self.update_or_create_by(_obj)
    attributes = {
      slug:               _obj[:slug],
      name:               _obj[:name],
      description:        _obj[:description],
      image_url:          _obj[:image_url],
      large_image_url:    _obj[:large_image_url],
      discord_url:        _obj[:discord_url],
      telegram_url:       _obj[:telegram_url],
      external_url:       _obj[:external_url],
      twitter_username:   _obj[:twitter_username],
      instagram_username: _obj[:instagram_username],
      payout_address:     _obj[:payout_address],
    }
    collection = self.find_or_create_by(slug: _obj[:slug])
    collection.update(attributes)
    return collection.id
  end


  def self.create_by_slug(_obj)
    (self.find_or_create_by(slug: _obj[:slug]) do |collection|
      collection.name               = _obj[:name]
      collection.description        = _obj[:description]
      collection.image_url          = _obj[:image_url]
      collection.large_image_url    = _obj[:large_image_url]
      collection.discord_url        = _obj[:discord_url]
      collection.telegram_url       = _obj[:telegram_url]
      collection.external_url       = _obj[:external_url]
      collection.twitter_username   = _obj[:twitter_username]
      collection.instagram_username = _obj[:instagram_username]
      collection.payout_address     = _obj[:payout_address]
    end).id
  end
end

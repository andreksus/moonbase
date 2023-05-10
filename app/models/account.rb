class Account < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search_by_name,
                  against: :name,
                  using: { tsearch: { prefix: true } }
  pg_search_scope :search_by_address,
                  against: :address,
                  using: { tsearch: { prefix: true } }

  if Rails.env.production? && ENV['BACKGROUND_WORKER_NUMBER'] != 'second'
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    def as_indexed_json(_options = {})
      self.as_json(
        only: [:id, :name, :address]
      )
    end
  end

  def self.create_by_address(address, username = nil, profile_img_url = "")
    (self.find_or_create_by(address: address) do |account|
      account.name = username
      account.profile_img_url = profile_img_url if profile_img_url.present?
    end).id
  end

  def self.update_or_create_by_address(address, username = nil, profile_img_url = "")
    attributes = {
      name:            username,
      profile_img_url: profile_img_url
    }
    account = self.find_or_create_by(address: address)
    account.update(attributes)
    return account.id
  end

end

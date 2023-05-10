class TrackedWalletAddress < ApplicationRecord
  belongs_to :user
  include PgSearch::Model
  pg_search_scope :search_by_name,
                  against: :user_name,
                  using: { tsearch: { prefix: true } }
  pg_search_scope :search_by_address,
                  against: :address,
                  using: { tsearch: { prefix: true } }
end

class AddEventIdIndexToTrendingCollections < ActiveRecord::Migration[6.1]
  def change
    add_index :trending_collections, [:event_id, :created_date], unique: true
  end
end

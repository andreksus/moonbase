class AddIndexesToTrendingCollections < ActiveRecord::Migration[6.1]
  def change
    add_index :trending_collections, :slug
    add_index :trending_collections, :created_date
  end
end

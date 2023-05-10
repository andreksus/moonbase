class DropTrendingCollections < ActiveRecord::Migration[6.1]
  def change
    drop_table :trending_collections
  end
end

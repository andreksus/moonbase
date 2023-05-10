class CreateTrendingCollections < ActiveRecord::Migration[6.1]
  def change
    create_table :trending_collections do |t|
      t.string :name
      t.text :description
      t.string :image_url
      t.string :large_image_url
      t.string :slug, null: false
      t.string :twitter_username
      t.string :discord_url
      t.bigint :asset_id
      t.bigint :asset_token_id
      t.bigint :asset_num_sales
      t.string :asset_image_url
      t.string :asset_name
      t.text :asset_description
      t.float :total_price
      t.datetime :created_date
      t.bigint :event_id

      t.timestamps
    end
  end
end

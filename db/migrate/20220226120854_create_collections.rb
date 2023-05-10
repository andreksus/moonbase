class CreateCollections < ActiveRecord::Migration[6.1]
  def change
    create_table :collections do |t|
      t.text :slug
      t.text :name
      t.text :url
      t.text :image_url
      t.text :large_image_url
      t.text :discord_url
      t.text :telegram_url
      t.text :twitter_username
      t.text :instagram_username

      t.timestamps
    end
    add_index :collections, :slug, unique: true
  end
end

class CreateListings < ActiveRecord::Migration[6.1]
  def change
    create_table :listings do |t|
      t.float :base_price
      t.bigint :quantity
      t.text :payment_token
      t.datetime :created_date, null: false
      t.datetime :listing_time
      t.datetime :expiration_time
      t.string :order_hash
      t.bigint :maker_id
      t.bigint :taker_id

      t.references :asset, index: true, foreign_key: true
      t.index ["created_date"], name: "index_listings_on_created_date"
      t.index ["order_hash"], name: "index_listings_on_order_hash", unique: true


      t.timestamps
    end
  end
end

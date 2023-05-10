class CreateItemSales < ActiveRecord::Migration[6.1]
  def change
    create_table :item_sales do |t|
      t.float :sale_price
      t.bigint :quantity
      t.text :payment_token
      t.datetime :created_date, null: false
      t.string :order_hash
      t.bigint :maker_id
      t.bigint :taker_id
      t.text :img_url
      t.text :token_id

      t.references :asset, index: true, foreign_key: true

      t.timestamps
    end
  end
end

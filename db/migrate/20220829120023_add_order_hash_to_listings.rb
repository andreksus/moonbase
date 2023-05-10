class AddOrderHashToListings < ActiveRecord::Migration[6.1]
  def change
      add_column :listings, :order_hash, :string, null: false, default: ""
      add_index :listings, :order_hash, unique: true
    end
end

class RemoveIndexFromListings < ActiveRecord::Migration[6.1]
  def change
    remove_index :listings, :order_hash
    remove_column :listings, :order_hash
    remove_column :listings, :active
  end
end

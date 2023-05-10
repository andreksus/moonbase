class AddCollectionIdToItemSale < ActiveRecord::Migration[6.1]
  def change
    add_column :item_sales, :collection_id, :bigint
  end
end

class AddContractAddressToItemSales < ActiveRecord::Migration[6.1]
  def change
    add_column :item_sales, :contract_address, :text
  end
end

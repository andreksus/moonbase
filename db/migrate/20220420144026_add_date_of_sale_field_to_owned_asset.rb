class AddDateOfSaleFieldToOwnedAsset < ActiveRecord::Migration[6.1]
  def change
    add_column :owned_assets, :date_of_sale, :datetime
  end
end

class AddPurchaseDateAndPurchasePriceFieldsToOwnedAssets < ActiveRecord::Migration[6.1]
  def change
    add_column :owned_assets, :purchase_date, :datetime
    add_column :owned_assets, :purchase_price_eth, :float
  end
end

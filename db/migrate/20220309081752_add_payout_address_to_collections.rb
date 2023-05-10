class AddPayoutAddressToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :payout_address, :text
  end
end

class AddContractAddressAndTokenIdToAsset < ActiveRecord::Migration[6.1]
  def change
    add_column :assets, :contract_address, :text, null: false
    add_column :assets, :token_id, :text, null: false

    add_index :assets, :token_id
    add_index :assets, :contract_address
  end
end

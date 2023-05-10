class AddContractAddressToCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :contract_address, :text
  end
end

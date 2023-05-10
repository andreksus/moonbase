class AddOwnerIdToAsset < ActiveRecord::Migration[6.1]
  def change
    add_column :assets, :account_id, :bigint, null: false
    add_foreign_key :assets, :accounts, on_delete: :cascade
  end
end

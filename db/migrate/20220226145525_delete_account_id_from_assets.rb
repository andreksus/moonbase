class DeleteAccountIdFromAssets < ActiveRecord::Migration[6.1]
  def change
    remove_column :assets, :account_id
  end
end

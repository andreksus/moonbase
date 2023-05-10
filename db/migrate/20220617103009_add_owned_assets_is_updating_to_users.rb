class AddOwnedAssetsIsUpdatingToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :owned_assets_is_updating, :boolean, default: false
  end
end

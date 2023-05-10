class AddOwnedAssetsIsUpdatingTimeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :owned_assets_is_updating_time, :datetime, default: nil, null: true
  end
end

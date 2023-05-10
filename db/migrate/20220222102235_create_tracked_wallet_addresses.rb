class CreateTrackedWalletAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :tracked_wallet_addresses do |t|
      t.string :user_name
      t.string :address
      t.references :user, index: true, foreign_key: true
      t.timestamps
    end
  end
end

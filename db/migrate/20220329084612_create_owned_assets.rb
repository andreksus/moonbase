class CreateOwnedAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :owned_assets do |t|
      t.references :user, index: true, foreign_key: true
      t.references :asset, index: true, foreign_key: true
      t.timestamps
    end
  end
end

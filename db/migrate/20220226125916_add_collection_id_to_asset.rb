class AddCollectionIdToAsset < ActiveRecord::Migration[6.1]
  def change
    add_column :assets, :collection_id, :bigint, null: false
    add_foreign_key :assets, :collections, on_delete: :cascade
  end
end

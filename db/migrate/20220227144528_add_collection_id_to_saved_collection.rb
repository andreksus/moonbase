class AddCollectionIdToSavedCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :saved_collections, :collection_id, :bigint, null: false
    add_index :saved_collections, :collection_id
    add_foreign_key :saved_collections, :collections
  end
end

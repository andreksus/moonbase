class AddIndexUserIdCollectionIdToSavedCollections < ActiveRecord::Migration[6.1]
  def change
    add_index :saved_collections, [:user_id, :collection_id], unique: true
  end
end

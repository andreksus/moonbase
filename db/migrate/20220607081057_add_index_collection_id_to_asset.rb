class AddIndexCollectionIdToAsset < ActiveRecord::Migration[6.1]
  def change
    add_index :assets, :collection_id
  end
end

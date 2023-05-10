class RemoveColumnsFromSavedCollection < ActiveRecord::Migration[6.1]
  def change
    remove_column :saved_collections, :name
    remove_column :saved_collections, :image_url
    remove_column :saved_collections, :stats
  end
end

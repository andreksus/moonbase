class RemoveSlugFromSavedCollections < ActiveRecord::Migration[6.1]
  def change
    remove_column :saved_collections, :slug
  end
end

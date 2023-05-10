class AddSlugIndexToSavedCollection < ActiveRecord::Migration[6.1]
  def change
    add_index :saved_collections, :slug
  end
end

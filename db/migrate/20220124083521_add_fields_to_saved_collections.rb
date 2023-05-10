class AddFieldsToSavedCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :saved_collections, :stats, :text, default: ""
    add_column :saved_collections, :image_url, :string
    add_column :saved_collections, :name, :string
  end
end

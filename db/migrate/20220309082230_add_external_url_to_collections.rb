class AddExternalUrlToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :external_url, :text
  end
end

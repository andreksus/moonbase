class RemoveUrlFromCollection < ActiveRecord::Migration[6.1]
  def change
    remove_column :collections, :url
  end
end

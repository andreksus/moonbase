class CreateSavedCollections < ActiveRecord::Migration[6.1]
  def change
    create_table :saved_collections do |t|
      t.string :slug, null: false, default: ''
      t.timestamps
    end
    add_reference :saved_collections, :user, index: true, foreign_key: true
  end
end

class AddActiveFieldToListings < ActiveRecord::Migration[6.1]
  def change
    add_column :listings, :active, :boolean, default: true, null: false
  end
end

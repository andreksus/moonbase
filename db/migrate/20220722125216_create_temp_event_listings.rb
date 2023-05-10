class CreateTempEventListings < ActiveRecord::Migration[6.1]
  def change
    create_table :temp_event_listings, id: false do |t|
      t.bigint :id, null: false
      t.datetime :created_date, null: false
      t.timestamps
    end
    add_index :temp_event_listings, [:id, :created_date], unique: true
  end
end

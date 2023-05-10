class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events, id: false  do |t|
      t.bigint :id, null: false
      t.datetime :created_date, null: false
      t.numeric :quantity, null: false, precision: 9, scale: 9
      t.decimal :total_price, null: false, precision: 9, scale: 9
      t.bigint :asset_id, null: false
      t.bigint :collection_id, null: false
      t.bigint :seller_account_id, null: false
      t.bigint :from_account_id, null: false
      t.bigint :to_account_id, null: false
      t.bigint :winner_account_id, null: false



      t.timestamps
    end

    add_foreign_key :events, :assets, on_delete: :cascade
    add_foreign_key :events, :collections, on_delete: :cascade
    add_foreign_key :events, :accounts, column: :seller_account_id, on_delete: :cascade
    add_foreign_key :events, :accounts, column: :from_account_id, on_delete: :cascade
    add_foreign_key :events, :accounts, column: :to_account_id, on_delete: :cascade
    add_foreign_key :events, :accounts, column: :winner_account_id, on_delete: :cascade

    add_index :events, :asset_id
    add_index :events, :collection_id
    add_index :events, :created_date
    add_index :events, :winner_account_id
    add_index :events, [:id, :created_date], unique: true

  end
end

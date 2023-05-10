class CreateEventTransfers < ActiveRecord::Migration[6.1]
  def change
    create_table :event_transfers, id: false  do |t|
      t.bigint :id, null: false
      t.datetime :created_date, null: false
      t.integer :quantity, null: true, precision: 9, scale: 9
      t.float :total_price, null: true, precision: 9, scale: 9
      t.bigint :asset_id, null: false
      t.bigint :collection_id, null: false
      t.bigint :seller_account_id, null: true
      t.bigint :from_account_id, null: true
      t.bigint :to_account_id, null: true
      t.bigint :winner_account_id, null: true
      t.string :transaction_hash
      t.string :transaction_index
      t.string :block_hash
      t.string :block_number
      t.timestamps
    end

    add_foreign_key :event_transfers, :assets, on_delete: :cascade
    add_foreign_key :event_transfers, :collections, on_delete: :cascade
    add_foreign_key :event_transfers, :accounts, column: :seller_account_id, on_delete: :cascade
    add_foreign_key :event_transfers, :accounts, column: :from_account_id, on_delete: :cascade
    add_foreign_key :event_transfers, :accounts, column: :to_account_id, on_delete: :cascade
    add_foreign_key :event_transfers, :accounts, column: :winner_account_id, on_delete: :cascade

    add_index :event_transfers, :asset_id
    add_index :event_transfers, :collection_id
    add_index :event_transfers, :created_date
    add_index :event_transfers, :winner_account_id
    add_index :event_transfers, [:id, :created_date], unique: true
  end
end

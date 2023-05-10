class AddTransactionsFieldToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :transaction_hash, :string
    add_column :events, :transaction_index, :string
    add_column :events, :block_hash, :string
    add_column :events, :block_number, :string
  end
end

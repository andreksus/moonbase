class AddPaymentSymbolToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :payment_symbol, :string, null: false
    add_index :events, :payment_symbol
  end
end

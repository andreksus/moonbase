class ChangeMoneyTypeOnEvents < ActiveRecord::Migration[6.1]
  def change
    change_column :events, :quantity, :integer
    change_column :events, :total_price, :float
  end
end

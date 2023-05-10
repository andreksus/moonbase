class AddNameToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :name, :text
    add_index :accounts, :name
  end
end

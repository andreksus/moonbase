class CreateAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :accounts do |t|
      t.text :user_name
      t.text :address, null: false


      t.timestamps
    end

    add_index :accounts, :address, unique: true
  end
end

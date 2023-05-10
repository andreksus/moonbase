class RemoveUserNameFromAccounts < ActiveRecord::Migration[6.1]
  def change
    remove_column :accounts, :user_name
  end
end

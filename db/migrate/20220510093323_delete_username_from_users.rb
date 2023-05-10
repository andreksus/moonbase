class DeleteUsernameFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_index :users, column: [:username], name: "index_users_on_username"
    remove_column :users, :username
  end
end

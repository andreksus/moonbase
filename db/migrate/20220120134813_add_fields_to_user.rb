class AddFieldsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :wallet_address, :string
    add_column :users, :username, :string
    add_column :users, :phone_number, :string
    add_column :users, :sms_alert, :boolean, default: false
  end
end

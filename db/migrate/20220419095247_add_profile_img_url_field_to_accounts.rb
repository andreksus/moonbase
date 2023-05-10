class AddProfileImgUrlFieldToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :profile_img_url, :string, default: ""
  end
end

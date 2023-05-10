class AddChannelKeyFieldToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :channel_key, :string, default: ""
  end
end

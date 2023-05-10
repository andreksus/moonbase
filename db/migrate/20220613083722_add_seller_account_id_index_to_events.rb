class AddSellerAccountIdIndexToEvents < ActiveRecord::Migration[6.1]
  def change
    add_index :events, :seller_account_id
  end
end

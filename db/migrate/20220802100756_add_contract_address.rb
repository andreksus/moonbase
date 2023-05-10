class AddContractAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :payment_histories, :created_date, :datetime
    add_column :payment_histories, :updated_date, :datetime
    add_column :payment_histories, :contract_address, :string
  end
end

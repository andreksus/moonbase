class CreatePaymentHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_histories do |t|
      t.string :transaction_hash
      t.string :gas_price
      t.string :hex_value
      t.string :from
      t.string :to
      t.integer :status, null: false, default: 0
      # t.datetime :created
      # t.datetime :updated

      t.timestamps
    end
  end
end

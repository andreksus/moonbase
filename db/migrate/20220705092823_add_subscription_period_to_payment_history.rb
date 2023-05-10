class AddSubscriptionPeriodToPaymentHistory < ActiveRecord::Migration[6.1]
  def change
    add_column :payment_histories, :period, :integer
  end
end

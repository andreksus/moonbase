class AddIntervalCountToPlans < ActiveRecord::Migration[6.1]
  def change
    add_column :plans, :interval_count, :integer, default: 1
  end
end

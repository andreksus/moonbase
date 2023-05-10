class AddHypertable < ActiveRecord::Migration[6.1]
  def change
    remove_column :trending_collections, :id
    execute "SELECT create_hypertable('trending_collections', 'created_date');"
  end
end

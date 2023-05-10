class CreateHyperTableForEvents < ActiveRecord::Migration[6.1]
  def change
    execute "SELECT create_hypertable('events', 'created_date');"
  end
end

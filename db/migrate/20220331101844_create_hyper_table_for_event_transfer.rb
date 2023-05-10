class CreateHyperTableForEventTransfer < ActiveRecord::Migration[6.1]
  def change
    execute "SELECT create_hypertable('event_transfers', 'created_date');"
  end
end

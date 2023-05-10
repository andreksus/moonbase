class CreateAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :assets do |t|
      t.text :name
      t.text :description
      t.text :url
      t.text :image_url
      t.datetime :contract_date
      t.timestamps
    end
  end
end

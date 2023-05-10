class AddAnimationUrlFieldToAsset < ActiveRecord::Migration[6.1]
  def change
    add_column :assets, :animation_url, :string
  end
end

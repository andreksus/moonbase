class ChangeAssetTokenIdTypeInTrendingCollection < ActiveRecord::Migration[6.1]
  def change
    change_column :trending_collections, :asset_token_id, :string
  end
end

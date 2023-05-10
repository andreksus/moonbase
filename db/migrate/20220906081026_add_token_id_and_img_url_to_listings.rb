class AddTokenIdAndImgUrlToListings < ActiveRecord::Migration[6.1]
  def change
    add_column :listings, :img_url, :text
    add_column :listings, :token_id, :text
  end
end

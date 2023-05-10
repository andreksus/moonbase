class SavedCollection < ApplicationRecord
  belongs_to :user

  def count_of_tracking
    SavedCollection.where(collection_id: self.collection_id).count
  end
end

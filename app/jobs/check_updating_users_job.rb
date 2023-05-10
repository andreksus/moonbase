class CheckUpdatingUsersJob < ApplicationJob
  queue_as :default


  def perform()
    self.class.perform()
  end

  def self.perform()
    User.where.not(owned_assets_is_updating_time: nil, owned_assets_is_updating: false)
         .where("owned_assets_is_updating_time + (20 ||' minutes')::interval < ?", DateTime.now)
         .update_all({owned_assets_is_updating_time: nil, owned_assets_is_updating: false})
    ""
  end
end

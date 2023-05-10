class DownloadOwnedAssetsJob < ApplicationJob
  queue_as 'awseb-e-xpk2xpwnks-stack-AWSEBWorkerQueue-1PDFAO0R4PSAY'

  def perform(user_id)
    self.class.perform(user_id)
  end

  def self.perform(user_id)
    PortfolioService.download_owned_asset_to_user(user_id)
  end

end

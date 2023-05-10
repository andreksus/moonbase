class DeleteListingsWhichExpirationJob < ApplicationJob
  queue_as 'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1'
  # queue_as 'MoonbaseListingsWorker'
  def perform()
    self.class.perform()
  end

  def self.perform()
    Listing.where("expiration_time < ?", DateTime.now.utc).destroy_all
    ""
    puts "DELETED EXPIRED LISTINGS"
  end
end

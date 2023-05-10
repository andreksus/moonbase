class PullingGasFeeJob < ApplicationJob
  queue_as 'awseb-e-xpk2xpwnks-stack-AWSEBWorkerQueue-1PDFAO0R4PSAY'

  def perform()
      self.class.perform()
  end

  def self.perform()
    12.times do
      @gas_fee = GasFee.new()
      fee = @gas_fee.response
      @gas_fee.redis_submit(fee)
      sleep(5)
    end
  end

end
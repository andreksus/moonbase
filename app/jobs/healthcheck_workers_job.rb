require 'uri'
require 'net/http'
class HealthcheckWorkersJob < ApplicationJob
  queue_as ENV['BACKGROUND_WORKER_NUMBER'] == 'first' ? 'awseb-e-xpk2xpwnks-stack-AWSEBWorkerQueue-1PDFAO0R4PSAY' : 'second' ? 'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1' : 'MoonbaseListingsWorker'

  def perform()
    self.class.perform()
  end

  def self.perform()
    url = URI.parse('https://betteruptime.com/api/v1/heartbeat/yxboSrPGDz3awEPR9RA3nHX2')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    puts response
    puts "AAAAAAAA"
  end
end

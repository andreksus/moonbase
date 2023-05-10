require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require "redis"


class GasFee

  def initialize
    @url = "https://api.blocknative.com/gasprices/blockprices"
    @key = ""
  end

  def response()
    url = URI(@url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = @key
    http.request(request).body
  end

  def redis_submit(response)
    $redis.publish("gas", {res: response})
      # redis = Redis.new
      # redis.set("gas", response)

  end
end
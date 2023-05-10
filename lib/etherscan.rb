require 'uri'
require 'net/http'
require 'openssl'
require 'json'

class Etherscan

  def initialize
    @url = "https://api.etherscan.io/api?"
    # @module = "account"
    # @action = "txlist"
    # @address = "0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a"
    # @startblock = "0"
    # @endblock = "99999999"
    # @page = 1
    # @offset = 10
    # @sort = "desc"
    @apikey = ""
  end

  def response(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    http.request(request).body
  end

  def get_normal_transactions_by_address(address = '0x33a92621c9b45329bb4ff1d5ee14eb15cf2e4638', page = 1, offset = 10, sort = 'desc')
    url = URI(@url + "module=account&action=txlist&address=#{address}&page=#{page}&offset=#{offset}&sort=#{sort}&apikey=#{@apikey}")
    JSON.parse(response(url), symbolize_names: true)
  end

  def get_token_info(address = '0x701a038af4bd0fc9b69a829ddcb2f61185a49568', page = 1, offset = 10, sort = 'desc')
    url = URI(@url + "module=token&action=tokeninfo&contractaddress=#{address}&apikey=#{@apikey}")
    JSON.parse(response(url), symbolize_names: true)
  end

  def get_gas_by_hash(hash = '0x78f6c6763cc236f9ebb58aeb46c91a4f2480abfa5af35cd276494beb06f10dace')
    url = URI(@url + "module=proxy&action=eth_getTransactionByHash&txhash=#{hash}&apikey=#{@apikey}")
    JSON.parse(response(url), symbolize_names: true)
  end

end

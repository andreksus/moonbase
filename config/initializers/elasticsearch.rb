require 'elasticsearch/model'
require 'faraday_middleware/aws_sigv4'
require 'faraday_middleware'
# Elasticsearch::Model.client = Elasticsearch::Client.new log:true, transport_options: { request: { timeout: 5 } }
if Rails.env.production?
  Elasticsearch::Model.client = Elasticsearch::Client.new(url: "https://vpc-dev-elasticsearch-moon-ihs3cvvatcexk6pgunxcmbm5xq.us-east-2.es.amazonaws.com", log: true) do |f|
    f.request :aws_sigv4,
              service: 'es',
              region: 'us-east-2',
              access_key_id: "AKIA2RFWYKEYXJO3KGXL",
              secret_access_key: "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"
  end
end
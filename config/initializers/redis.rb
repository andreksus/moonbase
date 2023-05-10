# frozen_string_literal: true

# Redis.current = Redis.new(url:  'redis://127.0.0.1',
#                           port: '6379',
#                           db:   '0')
if Rails.env.production?
  $redis = Redis.new(host: "moonbase-redis-001.n1svwf.0001.use2.cache.amazonaws.com")
else
  $redis = Redis.new
end

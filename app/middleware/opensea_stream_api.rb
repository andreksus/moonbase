require 'faye/websocket'
require 'eventmachine'
class OpenseaStreamApi
  def initialize(app)
    @app = app

    Thread.new {
      EM.run {
        begin
        ws = Faye::WebSocket::Client.new('wss://stream.openseabeta.com/socket/websocket?token=d6ff301be52345509d53293f7902b972', [], {

        })

        ws.on :open do |event|
          Rails.logger.info [:open]

          ws.send(
            {
              "topic": "phoenix",
              "event": "heartbeat",
              "payload": {},
              "ref": 0
            }.to_json
          )

          ws.send({
                    "topic": "collection:*",
                    "event": "phx_join",
                    "payload": {},
                    "ref": 0
                  }.to_json)
        end

        ws.on :message do |event|
          item = JSON.parse(event.data, symbolize_names: true)
          if item[:payload][:event_type] == 'item_listed' && item[:payload][:payload][:item][:chain][:name] == "ethereum"
            Listing.create_listing item[:payload]
            Rails.logger.info [:message, item]
          end
        end

        ws.on :close do |event|
          Rails.logger.info [:close, event.code, event.reason]
          ws = nil
        end


        rescue Exception => e
          Rails.logger.info "Faye::WebSocket Error: #{e.message}"
        end
      }
    } unless ENV['BACKGROUND_WORKER'] == 'true' && Rails.env.development?
  end

  def call(env)
      @app.call(env)
  end
end
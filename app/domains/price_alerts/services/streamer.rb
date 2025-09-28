# app/domains/price_alerts/services/streamer.rb

require "faye/websocket"
require "bigdecimal"
require "json"

module PriceAlerts
  module Services
    class Streamer
      BINANCE_WS_BASE_URL = "wss://stream.binance.com:9443/ws/stream"

      def initialize(initial_symbols:, ws: nil)
        @initial_symbols = initial_symbols
        @ws              = ws
      end

      def start
        streams = @initial_symbols.map { |s| "#{s.downcase}@trade" }.join("/")
        url     = "#{BINANCE_WS_BASE_URL}/#{streams}"

        EventMachine.run do
          @ws = Faye::WebSocket::Client.new(url)

          @ws.on :message do |event|
            PriceAlerts::TickProcessor.new.call(event.data)
          end

          @ws.on :close do |event|
            @ws = nil
            EventMachine.stop
          end

          @ws.on :error do |event|
            EventMachine.stop
          end
        end
      end
    end
  end
end

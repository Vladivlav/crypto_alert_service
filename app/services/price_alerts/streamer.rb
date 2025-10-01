require "faye/websocket"
require "bigdecimal"
require "json"

module PriceAlerts
  class Streamer
    BINANCE_WS_BASE_URL = "wss://stream.binance.com:9443/ws/stream"

    def initialize(initial_symbols:, ws: nil)
      @initial_symbols = initial_symbols
      @ws              = ws
    end

    def start
      # 1. Формируем URL подписки на все пары (stream1@trade/stream2@trade/...)
      # NOTE: Всегда используем нижний регистр для пар в URL
      streams = @initial_symbols.map { |s| "#{s.downcase}@trade" }.join("/")
      url = "#{BINANCE_WS_BASE_URL}/#{streams}"

      Rails.logger.info "Streamer connecting to: #{url}"

      EventMachine.run do
        @ws = Faye::WebSocket::Client.new(url)

        @ws.on :open do |event|
          Rails.logger.info "WebSocket connection OPENED successfully."
        end

        @ws.on :message do |event|
          Rails.logger.debug "PRICE TICK RECEIVED: #{event.data.truncate(100)}"

          PriceAlerts::TickProcessor.new.call(event.data)
        end

        @ws.on :close do |event|
          Rails.logger.warn "WebSocket connection CLOSED (Code: #{event.code}, Reason: #{event.reason}). Stopping EventMachine."
          @ws = nil
          EventMachine.stop # Останавливаем цикл, чтобы воркер Sidekiq мог завершиться
        end

        @ws.on :error do |event|
          Rails.logger.error "WebSocket ERROR: #{event.message}. Stopping EventMachine."
          EventMachine.stop
        end
      end
    end
  end
end

class WebSocketListenerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :listener, retry: false

  def perform
    active_symbols = PriceAlerts::Services::SymbolManager.new.active_symbols

    if active_symbols.empty?
      WebSocketListenerWorker.perform_in(60.seconds)
      return
    end

    streamer = PriceAlerts::Services::Streamer.new(initial_symbols: active_symbols)
    streamer.start

    Rails.logger.info "WebSocket connection closed gracefully. Restarting worker."
  rescue StandardError => e
    Rails.logger.error "WebSocket Listener crashed with #{e.class}: #{e.message}. Restarting immediately."
  ensure
    WebSocketListenerWorker.perform_async
  end
end

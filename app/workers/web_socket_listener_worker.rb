class WebSocketListenerWorker
  include Sidekiq::Worker

  # Настройки Sidekiq:
  # 1. Помещаем в отдельную очередь, чтобы не блокировать другие задачи.
  # 2. Устанавливаем retry: false, чтобы избежать автоматических попыток перезапуска Sidekiq
  #    при ошибках (мы делаем это вручную).
  sidekiq_options queue: :listener, retry: false

  def perform
    active_symbols = PriceAlerts::SymbolManager.new.active_symbols

    if active_symbols.empty?
      Rails.logger.warn "No active symbols found. Rescheduling check for 60 seconds."
      WebSocketListenerWorker.perform_in(60.seconds)
      return
    end

    Rails.logger.info "Starting WebSocket listener for: #{active_symbols.join(', ')}"

    streamer = PriceAlerts::Streamer.new(initial_symbols: active_symbols)
    streamer.start

    Rails.logger.info "WebSocket connection closed gracefully. Restarting worker."
  rescue StandardError => e
    Rails.logger.error "WebSocket Listener crashed with #{e.class}: #{e.message}. Restarting immediately."
  ensure
    WebSocketListenerWorker.perform_async
  end
end

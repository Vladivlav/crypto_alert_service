# config/initializers/crypto_pair_sync.rb

# Этот инициализатор будет запускать сервис синхронизации пар при старте приложения.
# Используем `after_initialize`, чтобы убедиться, что все остальные компоненты,
# включая базу данных, уже загружены.

Rails.application.config.after_initialize do
  Rails.logger.info "Starting crypto pair synchronization..."

  result = Binance::PairSyncService.new.call

  if result.failure?
    Rails.logger.info "Failed to synchronize pairs: #{result.failure}"
    return
  end

  new_pairs = result.value!

  if new_pairs.any?
    Rails.logger.info "Successfully synchronized. Added #{new_pairs.size} new pairs."
  else
    Rails.logger.info "No new pairs to add. Database is up to date."
  end
end

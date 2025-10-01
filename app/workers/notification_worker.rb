require "sidekiq"

class NotificationWorker
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  # Словарь для диспетчеризации: сопоставляет channel_type (из БД) с классом Sender Service
  SENDER_MAP = {
    "email" => Notifications::EmailSender
    # 'telegram' => Notifications::TelegramSender, # Добавить, когда будет реализован
    # 'sms' => Notifications::SmsSender           # Добавить, когда будет реализован
  }.freeze

  # Используем DI для моделей и сервисов
  def initialize(
    channel_model: NotificationChannel,
    threshold_model: PriceThreshold,
    formatter: Notifications::NotificationFormatter.new
  )
    @channel_model   = channel_model
    @threshold_model = threshold_model
    @formatter       = formatter
  end

  def perform(channel_id, threshold_id)
    channel   = channel_model.find(channel_id)
    threshold = threshold_model.find(threshold_id)
    message   = formatter.call(threshold, threshold.value)

    # 2. Диспетчеризация (выбор стратегии на основе типа канала)
    sender_class = SENDER_MAP[channel.channel_type]

    if sender_class
      # Создаем и вызываем сервис-отправитель с единым интерфейсом call()
      result = sender_class.new.call(channel: channel, threshold: threshold, message: message)

      if result.failure?
        Rails.logger.error "Notification dispatch failed for channel #{channel_id} via #{channel.channel_type}: #{result.failure}"
        # В случае ошибки отправки (например, API Telegram недоступен) - перевызываем raise для Sidekiq retry
        raise "Notification Sender Failed"
      end

      Rails.logger.info "Notification successfully dispatched for #{threshold.symbol} via #{channel.channel_type}"
    else
      Rails.logger.warn "NotificationWorker: Unknown channel type '#{channel.channel_type}' for channel ID #{channel_id}. Skipping."
    end

  rescue ActiveRecord::RecordNotFound => e
    # Если алерт или канал были удалены, пока задание находилось в очереди, мы просто пропускаем его.
    Rails.logger.warn "NotificationWorker: Record not found (deleted alert/channel): #{e.message}"
  rescue StandardError => e
    # Для всех остальных ошибок (кроме RecordNotFound) перевызываем raise для Sidekiq retry
    Rails.logger.error "NotificationWorker critical error: #{e.message}"
    raise
  end

  private

  attr_reader :channel_model, :threshold_model, :formatter
end

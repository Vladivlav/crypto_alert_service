# app/controllers/api/v1/telegram_webhooks_controller.rb

class Api::V1::TelegramWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    channel = NotificationChannel.find_by_webhook_token(params[:webhook_token])

    if channel
      Integrations::Telegram::MessageProcessor.call(channel: channel, message: telegram_webhook_params[:message].to_h)
      head :ok
    else
      Rails.logger.warn("Received webhook for an unknown token: #{params[:webhook_token]}")
      head :not_found
    end
  end

  private

  def telegram_webhook_params
    params.require(:telegram_webhook).permit(message: {})
  end
end

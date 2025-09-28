# app/models/notification_channel.rb

require "hashids"

class NotificationChannel < ApplicationRecord
  def webhook_token
    hashids_instance.encode(id)
  end

  def chat_id
    config["chat_id"]
  end

  def chat_id=(new_chat_id)
    config_will_change!
    config["chat_id"] = new_chat_id
  end

  private

  def hashids_instance
    @hashids_instance ||= begin
      salt = Rails.application.credentials.hashids_salt
      Hashids.new(salt, 8)
    end
  end

  class << self
    def find_by_webhook_token(token)
      id = hashids_instance.decode(token).first
      find_by(id: id) if id
    end

    private

    def hashids_instance
      @hashids_instance ||= begin
        salt = Rails.application.credentials.hashids_salt
        Hashids.new(salt, 8)
      end
    end
  end
end

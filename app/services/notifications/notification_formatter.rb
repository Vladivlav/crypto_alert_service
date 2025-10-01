# app/services/notifications/notification_formatter.rb

module Notifications
  class NotificationFormatter
    def call(threshold)
      operator_text = threshold.operator == "up" ? "higher" : "lower"

      "Price of the cryptopair #{threshold.symbol} become #{operator_text} than price of #{threshold.value}."
    end
  end
end

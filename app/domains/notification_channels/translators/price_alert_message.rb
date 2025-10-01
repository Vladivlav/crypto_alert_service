# app/domains/notification_channels/translators/price_alert_message.rb

module NotificationChannels
  module Translators
    class PriceAlertMessage
      def call(threshold)
        operator_text = threshold.operator == "up" ? "higher" : "lower"

        "Price of the cryptopair #{threshold.symbol} become #{operator_text} than price of #{threshold.value}."
      end
    end
  end
end

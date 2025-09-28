require "dry/monads"

module PriceAlerts
  module Guards
    class CrossoverCheck
      include Dry::Monads[:result, :do]

      STATE_ABOVE = "ABOVE"
      STATE_BELOW = "BELOW"

      def call(threshold, price, current_state)
        @threshold     = threshold
        @current_state = current_state
        @new_state     = price > threshold.value ? STATE_ABOVE : STATE_BELOW

        if send_alert?
          Success(new_state)
        else
          Failure("No need to alert")
        end
      end

      private

      attr_reader :threshold, :current_state, :new_state

      def send_alert?
        price_reached_on_rise? || price_reached_on_fall?
      end

      def price_reached_on_rise?
        crossover_occurred? && price_is_now_above_threshold? && threshold.alert_on_rising_price?
      end

      def price_reached_on_fall?
        crossover_occurred? &&  price_is_now_below_threshold? && threshold.alert_on_falling_price?
      end

      def price_is_now_above_threshold?
        new_state == STATE_ABOVE
      end

      def price_is_now_below_threshold?
        new_state == STATE_BELOW
      end

      def crossover_occurred?
        current_state != new_state
      end
    end
  end
end

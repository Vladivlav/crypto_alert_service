# frozen_string_literal: true

require "rails_helper"

module PriceAlerts
  RSpec.describe Guards::CrossoverCheck do
    STATE_ABOVE = described_class::STATE_ABOVE
    STATE_BELOW = described_class::STATE_BELOW

    # Устанавливаем базовое значение для порога, чтобы тесты на кроссовер были чистыми
    let(:threshold_value) { 100.0 }

    describe 'when no crossover occurs' do
      let(:threshold) { create :price_threshold, value: threshold_value, operator: "up" }

      context 'when price remains ABOVE the threshold' do
        let(:guard) { described_class.new.call(threshold, 105.0, STATE_ABOVE) }

        it 'returns Failure for not crossing the value' do
          expect(guard).to be_failure
        end
      end

      context 'when price remains BELOW the threshold' do
        let(:guard) { described_class.new.call(threshold, 95.0, STATE_BELOW) }

        it 'returns Failure for not crossing the value' do
          expect(guard).to be_failure
        end
      end
    end

    describe 'when price crosses UP (crossover occurred)' do
      let(:price) { 101.0 } # Новая цена выше порога
      let(:current_state) { STATE_BELOW }

      context 'when alert_on_rising_price? is TRUE' do
        # Порог установлен на 100.0, проверяем пересечение вверх
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "up" }
        let(:guard)     { described_class.new.call(threshold, price, current_state) }

        it 'returns Success with new state ABOVE' do
          expect(guard).to be_success
          expect(guard.value!).to eq STATE_ABOVE
        end
      end

      context 'when alert_on_rising_price? is FALSE' do
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "down" }
        let(:guard) { described_class.new.call(threshold, price, current_state) }

        it 'returns Failure (not set to alert on rise)' do
          expect(guard).to be_failure
        end
      end
    end

    describe 'when price crosses DOWN (crossover occurred)' do
      let(:price) { 99.0 } # Новая цена ниже порога
      let(:current_state) { STATE_ABOVE }

      context 'when alert_on_falling_price? is TRUE' do
        # Порог установлен на 100.0, проверяем пересечение вниз
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "down" }
        let(:guard) { described_class.new.call(threshold, price, current_state) }

        it 'returns Success with new state BELOW' do
          expect(guard).to be_success
          expect(guard.value!).to eq STATE_BELOW
        end
      end

      context 'when alert_on_falling_price? is FALSE' do
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "up" }
        let(:guard) { described_class.new.call(threshold, price, current_state) }

        it 'returns Failure (not set to alert on fall)' do
          expect(guard).to be_failure
        end
      end
    end

    describe 'when price is exactly equal to the threshold' do
      let(:price) { threshold_value } # 100.0

      context 'when current state is BELOW' do
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "up" } # Неважно, т.к. нет кроссовера
        let(:guard) { described_class.new.call(threshold, price, STATE_BELOW) }

        it 'returns Failure (no crossover)' do
          expect(guard).to be_failure
        end
      end

      context 'when current state is ABOVE' do
        # Когда цена равна threshold.value, new_state всегда BELOW.
        # Это создает кроссовер (ABOVE -> BELOW). Мы должны проверить,
        # сработает ли alert_on_falling_price?
        let(:threshold) { create :price_threshold, value: threshold_value, operator: "down" }
        let(:guard) { described_class.new.call(threshold, price, STATE_ABOVE) }

        it 'results in new_state BELOW and triggers alert if alert_on_falling_price? is true' do
          expect(guard).to be_success
          expect(guard.value!).to eq STATE_BELOW
        end
      end
    end
  end
end

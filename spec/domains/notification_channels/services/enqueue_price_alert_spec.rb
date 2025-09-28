require 'rails_helper'
require 'dry/monads'

module NotificationChannels
  RSpec.describe Services::EnqueuePriceAlert do
    include Dry::Monads[:result]

    let(:worker_mock) { class_double('NotificationWorker', perform_async: true) }
    let(:channel_model_mock) { class_double('NotificationChannel') }

    let(:service) do
      described_class.new(
        notification_worker: worker_mock,
        notification_channel_model: channel_model_mock
      )
    end

    let(:channel_1) { build :notification_channel, id: 101 }
    let(:channel_2) { build :notification_channel, id: 102 }
    let(:active_channels) { [ channel_1, channel_2 ] }

    let(:threshold) do
      build :price_threshold, id: 50, symbol: 'BTCUSDT', value: BigDecimal('70000.00')
    end

    before { allow(threshold).to receive(:value).and_return(BigDecimal('70000.00')) }

    context 'when there are active channels to send notification' do
      before { allow(channel_model_mock).to receive(:active).and_return(active_channels) }

      it 'calls perform_async on the worker for each active channel' do
        expect(worker_mock).to receive(:perform_async).once.with(
          channel_1.id, threshold.id, threshold.symbol, threshold.value.to_s
        )

        expect(worker_mock).to receive(:perform_async).once.with(
          channel_2.id, threshold.id, threshold.symbol, threshold.value.to_s
        )

        result = service.call(threshold)
        expect(result).to be_success
        expect(result.value!).to eq(active_channels)
      end
    end

    context 'when there are no active channels' do
      before do
        allow(channel_model_mock).to receive(:active).and_return([])
        allow(service).to receive(:puts)
      end

      it 'does NOT call perform_async and returns Success with an empty array' do
        expect(worker_mock).not_to receive(:perform_async)

        result = service.call(threshold)
        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context 'when NotificationWorker raises an error' do
      let(:error_message) { "Sidekiq connection error" }

      before do
        allow(channel_model_mock).to receive(:active).and_return(active_channels)
        allow(worker_mock).to receive(:perform_async).and_raise(StandardError, error_message)
      end

      it 'catches the exception and returns Failure with the error message' do
        result = service.call(threshold)
        expect(result).to be_failure
        expect(result.failure).to eq("Enqueue message error: #{error_message}")
      end
    end
  end
end

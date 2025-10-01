# spec/domains/price_thresholds/contracts/create_spec.rb
require 'rails_helper'

module PriceThresholds
  RSpec.describe Contracts::Create do
    subject(:validation) { described_class.new.call(params) }

    let(:valid_params) do
      {
        symbol: 'BTCUSDT',
        value: '65000.55',
        operator: 'up'
      }
    end

    # --- УСПЕШНЫЙ СЦЕНАРИЙ ---
    describe 'Success' do
      context 'with all valid parameters' do
        let(:params) { valid_params }
        it 'is successful' do
          expect(validation).to be_success
        end
      end

      context 'with high precision value' do
        let(:params) { valid_params.merge(value: '0.00012345') }
        it { is_expected.to be_success }
      end
    end

    # --- СЦЕНАРИИ ОШИБОК ---

    describe 'Failure: Symbol' do
      # ИСПРАВЛЕНО: ожидаем 'is missing'
      it 'fails when symbol is missing' do
        params = valid_params.except(:symbol)
        expect(described_class.new.call(params).errors.to_h).to include(symbol: [ 'is missing' ])
      end

      it 'fails when symbol contains lowercase letters' do
        params = valid_params.merge(symbol: 'BtcUsdt')
        expect(described_class.new.call(params).errors.to_h).to include(symbol: [ 'должен содержать только заглавные буквы и цифры' ])
      end

      it 'fails when symbol contains special characters' do
        params = valid_params.merge(symbol: 'BTC-USDT')
        expect(described_class.new.call(params).errors.to_h).to include(symbol: [ 'должен содержать только заглавные буквы и цифры' ])
      end
    end

    describe 'Failure: Operator' do
      # ИСПРАВЛЕНО: ожидаем 'is missing'
      it 'fails when operator is missing' do
        params = valid_params.except(:operator)
        expect(described_class.new.call(params).errors.to_h).to include(operator: [ 'is missing' ])
      end

      it 'fails when operator is invalid (e.g., ">")' do
        params = valid_params.merge(operator: '>')
        expect(described_class.new.call(params).errors.to_h).to include(operator: [ 'должен быть одним из: up (рост) или down (падение)' ])
      end
    end

    describe 'Failure: Value' do
      # ИСПРАВЛЕНО: ожидаем 'is missing'
      it 'fails when value is missing' do
        params = valid_params.except(:value)
        expect(described_class.new.call(params).errors.to_h).to include(value: [ 'is missing' ])
      end

      # ИСПРАВЛЕНО: проверяем, что массив ошибок содержит ожидаемую ошибку
      it 'fails when value is not a number (string)' do
        params = valid_params.merge(value: 'abc')
        # Проверяем, что массив ошибок для :value включает 'должно быть валидным числом'
        expect(described_class.new.call(params).errors.to_h[:value]).to include('должно быть валидным числом')
      end

      it 'fails when value is zero' do
        params = valid_params.merge(value: '0')
        expect(described_class.new.call(params).errors.to_h).to include(value: [ 'должно быть положительным числом' ])
      end

      # ИСПРАВЛЕНО: проверяем, что массив ошибок содержит ожидаемую ошибку
      it 'fails when value is negative' do
        params = valid_params.merge(value: '-100')
        expect(described_class.new.call(params).errors.to_h[:value]).to include('должно быть положительным числом')
      end

      it 'fails when value is a partial decimal (e.g., "123.")' do
        params = valid_params.merge(value: '123.')
        expect(described_class.new.call(params).errors.to_h).to include(value: [ 'должно быть валидным числом' ])
      end
    end
  end
end

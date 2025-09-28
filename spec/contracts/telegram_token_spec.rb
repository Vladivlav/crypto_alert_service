# spec/contracts/telegram_token_contract_spec.rb

require 'rails_helper'

RSpec.describe TelegramToken, type: :contract do
  let(:contract) { described_class.new }

  context 'когда данные валидны' do
    it 'возвращает успешный результат' do
      params = { token: '1234567:ABC-DEF1234ghIkl-789_a' }
      result = contract.call(params)

      expect(result).to be_success
      expect(result.errors).to be_empty
    end
  end

  context 'когда токен невалиден' do
    it 'возвращает ошибку, если формат токена неверный' do
      params = { token: 'invalid_token_format' }
      result = contract.call(params)

      expect(result).to be_failure
      expect(result.errors.to_h).to eq(token: [ 'invalid format' ])
    end

    it 'возвращает ошибку, если токен пустой' do
      params = { token: '' }
      result = contract.call(params)

      expect(result).to be_failure
      expect(result.errors.to_h).to eq(token: [ 'must be filled' ])
    end
  end

  context 'когда токен отсутствует' do
    it 'возвращает ошибку, если в теле запроса нет токена' do
      params = { random_key: 'some_value' }
      result = contract.call(params)

      expect(result).to be_failure
      expect(result.errors.to_h).to eq(token: [ 'is missing' ])
    end
  end
end

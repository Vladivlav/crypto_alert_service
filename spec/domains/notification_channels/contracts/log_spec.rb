require 'spec_helper'
require 'dry/validation'

module NotificationChannels
  RSpec.describe Contracts::Log do
    subject { described_class.new.call(input) }

    context 'when the input is valid' do
      # Проверяем базовое валидное имя
      context 'with a simple file name' do
        let(:input) { { file_name: 'test_log_file' } }

        it 'is successful' do
          expect(subject).to be_success
        end
      end

      # Проверяем имя с цифрами, подчеркиваниями и дефисами
      context 'with digits, underscores, and hyphens' do
        let(:input) { { file_name: 'channel-42_status' } }

        it 'is successful' do
          expect(subject).to be_success
        end
      end
    end

    # --- 2. Тесты на Провал (Невалидные данные) ---

    context 'when the input is invalid' do
      # 2a. Проверка обязательного поля (:file_name)
      context 'when file_name is missing' do
        let(:input) { {} }

        it 'is failure' do
          expect(subject).to be_failure
        end

        it 'returns a required error for file_name' do
          expect(subject.errors.to_h).to include(file_name: [ 'is missing' ])
        end
      end

      # 2b. Проверка пустого значения
      context 'when file_name is an empty string' do
        let(:input) { { file_name: '' } }

        it 'is failure' do
          expect(subject).to be_failure
        end

        it 'returns a "must be filled" error' do
          expect(subject.errors.to_h[:file_name]).to include('must be filled')
        end
      end

      context 'when file_name contains spaces' do
        let(:input) { { file_name: 'file with spaces' } }

        it 'is failure' do
          expect(subject).to be_failure
        end

        it 'returns the custom character error message' do
          expect(subject.errors.to_h[:file_name]).to include('Must contain of digits, chars and underscores')
        end
      end

      context 'when file_name contains special characters' do
        let(:input) { { file_name: 'file@!name' } }

        it 'is failure' do
          expect(subject).to be_failure
        end

        it 'returns the custom character error message' do
          expect(subject.errors.to_h[:file_name]).to include('Must contain of digits, chars and underscores')
        end
      end
    end
  end
end

# spec/domains/notification_channels/services/logs/check_file_exist_spec.rb

require 'rails_helper'
require 'dry/monads'

module NotificationChannels
  RSpec.describe Services::Logs::CheckFileExist do
    include Dry::Monads[:result]

    subject(:call)  { described_class.new.call("file_name") }
    let(:file_path) { described_class::CHANNEL_LOGS_DIR.join("file_name") }

    context "when filename already exists" do
      before { allow(File).to receive(:exist?).with(file_path).and_return(true) }

      it { is_expected.to be_failure }
    end

    context "when filename is free to use" do
      before { allow(File).to receive(:exist?).with(file_path).and_return(false) }

      it { is_expected.to be_success }
    end
  end
end

# app/controllers/api/v1/price_thresholds_controller.rb

module Api
  module V1
    class PriceThresholdsController < ApplicationController
      skip_before_action :verify_authenticity_token
      include ApiResultHelpers

      def create
        form     = PriceThresholds::Contracts::Create.new
        scenario = PriceThresholds::Scenarios::Create.new

        validate_params!(form.call(price_threshold_params)) do |valid_params|
          check_result!(scenario.call(valid_params)) do
            render json: { message: "Price threshold created successfully" }, status: :created
          end
        end
      end

      private

      def price_threshold_params
        params.require(:price_threshold).permit(:symbol, :value, :operator).to_h
      end
    end
  end
end

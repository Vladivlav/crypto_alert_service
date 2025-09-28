# app/controllers/api/v1/channels_controller.rb

module Api
  module V1
    class ChannelsController < ApplicationController
      skip_before_action :verify_authenticity_token
      include ApiResultHelpers

      def create
        factory_config  = ChannelCreation.for(params[:channel_type])
        contract        = factory_config[:contract].new
        scenario        = factory_config[:service].new

        validate_params!(contract.call(params[:channel][:config]&.to_unsafe_h)) do |valid_params|
          check_result!(scenario.call(token: valid_params[:token])) do |channel|
            render json: { message: "Channel created successfully", channel: channel }, status: :created
          end
        end
      rescue Errors::InvalidChannelType => e
        render json: { error: e.message }, status: :bad_request
      end
    end
  end
end

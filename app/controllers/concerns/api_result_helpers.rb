# app/controllers/concerns/api_result_helpers.rb

module ApiResultHelpers
  extend ActiveSupport::Concern

  private

  def validate_params!(result)
    if result.success?
      yield result.to_h
    else
      render json: { errors: result.errors.to_h }, status: :unprocessable_content
    end
  end

  def check_result!(result)
    if result.success?
      yield result.value!
    else
      render json: { error: result.failure }, status: :unprocessable_content
    end
  end
end

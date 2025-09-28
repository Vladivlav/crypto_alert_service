# app/errors/invalid_channel_type.rb

module Errors
  class InvalidChannelType < ArgumentError
    def initialize(message = "Unsupported channel type")
      super(message)
    end
  end
end

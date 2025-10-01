# app/errors/empty_tick_body.rb

module Errors
  class EmptyTickBody < ArgumentError
    def initialize(message = "There are no tick data in the message body")
      super(message)
    end
  end
end

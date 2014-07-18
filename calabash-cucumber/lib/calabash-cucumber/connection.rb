require 'singleton'
require 'calabash-cucumber/http_helpers'

module Calabash
  module Cucumber

    # @!visibility private
    class Connection
      include Singleton
      include HTTPHelpers

      def client
        @http
      end

    end
  end
end
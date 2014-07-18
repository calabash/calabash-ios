require 'calabash-cucumber/connection'

module Calabash
  module Cucumber

    # @!visibility private
    module ConnectionHelpers

      # @!visibility private
      def http(*args)
        connection.http(*args)
      end

      # @!visibility private
      def connection
        Calabash::Cucumber::Connection.instance
      end

    end
  end
end
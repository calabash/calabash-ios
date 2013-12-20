require 'calabash-cucumber/connection'

module Calabash
  module Cucumber
    module ConnectionHelpers

      def http(*args)
        connection.http(*args)
      end

      def connection
        Calabash::Cucumber::Connection.instance
      end

    end
  end
end
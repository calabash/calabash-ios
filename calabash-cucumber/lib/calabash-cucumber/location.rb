require 'location-one'

module Calabash
  module Cucumber
    module Location
      include Calabash::Cucumber::Core

      def set_location(options)
        p @http
        uri = url_for('uia')
        client = LocationOne::Client.new({:host => uri.host, :port => uri.port}, @http)
        res = client.change_location(options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "set_location #{options}, failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

    end
  end
end

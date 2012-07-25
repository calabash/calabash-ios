require 'location-one'
require 'geocoder'

module Calabash
  module Cucumber
    module Location
      include Calabash::Cucumber::Core

      def set_location(options)
        uri = url_for('uia')
        client = LocationOne::Client.new({:host => uri.host, :port => uri.port, :path => '/uia'}, @http)
        res = client.change_location(options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "set_location #{options}, failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def location_for_place(place)
         LocationOne::Client.location_by_place place
      end

    end
  end
end

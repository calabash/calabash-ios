require 'geocoder'

module Calabash
  module Cucumber
    module Location
      include Calabash::Cucumber::Core

      def set_location(options)
        ##TODO extracted from location-one Not implemented
        raise "Not re-implemented"
        uri = url_for('uia')
        res = change_location(options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "set_location #{options}, failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def location_for_place(place)
        results = Geocoder.search(place)
        raise "Got no results for #{place}" if results.empty?
        results.first
      end

      def change_location(options, opt_data={})
        if (options[:latitude] and not options[:longitude]) or
            (options[:longitude] and not options[:latitude])
          raise "Both latitude and longitude must be specified if either is."
        end
        if (options[:latitude])
          change_location_by_coords(options[:latitude], options[:longitude], opt_data)
        else
          if not options[:place]
            raise "Either :place or :latitude and :longitude must be specified."
          end
          change_location_by_place(options[:place], opt_data)
        end
      end

      def change_location_by_coords(lat, lon, opt_data={})

        body_data = {:action => :change_location,
                     :latitude => lat,
                     :longitude => lon}.merge(opt_data)



        body = make_http_request(
            :uri => URI.parse("http://#{@backend[:host]}:#{@backend[:port]}#{@backend[:path]}"),
            :method => :post,
            :body => body_data.to_json
        )


        unless body
          raise "Set location change failed, for #{lat}, #{lon} (#{body})."
        end
        body
      end

      def change_location_by_place(place, opt_data={})
        best_result = location_for_place(place)
        change_location_by_coords(best_result.latitude, best_result.longitude, opt_data)
      end


    end
  end
end

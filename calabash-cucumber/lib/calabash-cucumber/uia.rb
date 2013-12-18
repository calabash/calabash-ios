require 'edn'

module Calabash
  module Cucumber
    module UIA

      def uia(command,options={})
        res = http({:method => :post, :path => 'uia'}, {command:command}.merge(options))
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "uia send failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results'].first
      end

      def send_uia_command(opts ={})
        #deprecated, poor method signature
        #use uia("uia-js...",options)
        uia(opts[:command], opts)
      end

      def uia_query(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:query, queryparts)
      end

      def uia_names(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:names, queryparts)
      end

      def uia_tap(*queryparts)
        uia_handle_command(:tap, queryparts)
      end

      def uia_tap_mark(mark)
        uia_handle_command(:tapMark, mark)
      end

      def uia_tap_offset(offset)
        uia_handle_command(:tapOffset, offset)
      end

      def uia_pan(from_q, to_q)
        uia_handle_command(:pan, from_q, to_q)
      end

      def uia_pan_offset(from, to, options)
        uia_handle_command(:panOffset, from, to, options)
      end

      def uia_swipe(*queryparts)
        uia_handle_command(:swipe, queryparts)
      end

      def uia_swipe_offset(offset, options)
        uia_handle_command(:swipeOffset, offset, options)
      end

      def uia_pinch(*queryparts)
        uia_handle_command(:pinch, queryparts)
      end

      def uia_pinch_offset(in_or_out, offset, duration)
        uia_handle_command(:pinchOffset, in_or_out, offset, duration)
      end

      def uia_scroll_to(*queryparts)
        uia_handle_command(:scrollTo, queryparts)
      end

      def uia_element_exists?(*queryparts)
        uia_handle_command(:elementExists, queryparts)
      end

      def uia_element_does_not_exist?(*queryparts)
        uia_handle_command(:elementDoesNotExist, queryparts)
      end

      def uia_screenshot(name)
        uia_handle_command(:screenshot, name)
      end

      def uia_type_string(string)
        res = uia_handle_command(:typeString, string)
        status = res['status']
        if status.eql?('error')
          value = res['value']
          screenshot_and_raise "could not type '#{string}' - '#{value}'"
        end
      end

      def uia_enter
        uia_handle_command(:enter)
      end

      def uia_set_location(options)
        validate_hash_is_location!(options)
        if options[:place]
          place = options[:place]
          search_results = Geocoder.search(place)
          raise "Got no results for #{place}" if search_results.empty?
          loc = search_results.first
          loc_data = {'latitude'=>loc.latitude, 'longitude'=>loc.longitude}
        elsif options.is_a?(Hash)
          loc_data = options
        end
        uia_handle_command(:setLocation, loc_data)
      end

      def uia_send_app_to_background(secs)
        uia_handle_command(:deactivate, secs)
      end

      def uia_handle_command(cmd, *query_args)
        args = query_args.map do |part|
          if part.is_a?(String)
            "'#{escape_uia_string(part)}'"
          else
            "'#{escape_uia_string(part.to_edn)}'"
          end
        end
        command = %Q[uia.#{cmd}(#{args.join(', ')})]
        if ENV['DEBUG'] == '1'
          puts "Sending UIA command"
          puts command
        end
        s = uia(command)
        if ENV['DEBUG'] == '1'
          puts "Result"
          p s
        end
        if s['status'] == 'success'
          s['value']
        else
          s
        end
      end

      def escape_uia_string(string)
        #TODO escape '\n in query
        escape_quotes string
      end

      private
      def validate_hash_is_location!(options)
        return if options[:latitude] and options[:longitude]
        if (options[:latitude] and not options[:longitude]) ||
            (options[:longitude] and not options[:latitude])
          raise 'Both latitude and longitude must be specified if either is.'
        elsif not options[:place]
            raise 'Either :place or :latitude and :longitude must be specified.'
        end
      end


    end
  end
end
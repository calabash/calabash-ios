require 'edn'
require 'location-one'

module Calabash
  module Cucumber
    module UIA

      def send_uia_command(opts ={})
        launcher = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        run_loop = opts[:run_loop] || (launcher && launcher.active? && launcher.run_loop)
        command = opts[:command]
        raise ArgumentError, 'please supply :run_loop or instance var @calabash_launcher' unless run_loop
        raise ArgumentError, 'please supply :command' unless command
        RunLoop.send_command(run_loop, opts[:command])
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
        uia_handle_command(:elementDoesNotExist, name)
      end

      def uia_type_string(string)
        uia_handle_command(:typeString, string)
      end

      def uia_enter()
        uia_handle_command(:enter)
      end

      def uia_set_location(place)
        if place.is_a?(String)
          loc = LocationOne::Client.location_by_place(place)
          loc_data = {"latitude"=>loc.latitude, "longitude"=>loc.longitude}
        else
          loc_data = place
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
        s=send_uia_command :command => command
        if ENV['DEBUG'] == '1'
          puts "Result"
          p s
        end
        if s['status'] == 'success'
          s['value']
        else
          raise s
        end
      end

      def escape_uia_string(string)
        #TODO escape '\n in query
        escape_quotes string
      end

    end
  end
end
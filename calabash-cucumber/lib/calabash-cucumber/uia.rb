require 'edn'
require 'json'
# required for ruby 1.8
require 'enumerator'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber
    # Low-level module for interacting directly with UIA
    # See also {https://developer.apple.com/library/ios/documentation/ToolsLanguages/Reference/UIAElementClassReference/UIAElement/UIAElement.html}
    # Typically used to interact with System or remote views.
    module UIA

      include Calabash::Cucumber::Logging

      # executes raw JavaScript in the UIAutomation environment (using `eval`).
      # @param {String} command the JavaScript snipplet to execute
      # @return {Object} the result returned by the UIA process
      def uia(command,options={})
        res = http({:method => :post, :path => 'uia'}, {:command => command}.merge(options))
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          raise "uia action failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results'].first
      end

      # @!visibility private
      def uia_wait_tap(query, options={})
        res = http({:method => :post, :path => 'uia-tap'}, {:query => query}.merge(options))
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          raise "uia-tap action failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      # Invoke a Calabash query inside the UIAutomation Calabash engine
      # Note that this traverses the UIA (accessibility) hierarchy.
      # @example uia query equivalent of "button marked:'Hello'"
      #   uia_query :button, marked:'Hello'
      # @param {Array} queryparts array of segments in the query, e.g., `:button, {marked:'Hello'}`
      # @return {Array<Hash>} UIAElements matching the query in serialized form.
      def uia_query(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:query, queryparts)
      end

      # @!visibility private
      def uia_query_el(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:queryEl, queryparts)
      end

      # Invoke a Calabash query inside the UIAutomation Calabash engine - includes all UIAWindows.
      # Note that this traverses the UIA (accessibility) hierarchy.
      # @example uia query equivalent of "button marked:'Hello'"
      #   uia_query_windows :button
      # @param {Array} queryparts array of segments in the query, e.g., `:button, {marked:'Hello'}`
      # @return {Array<Hash>} UIAElements matching the query in serialized form.
      def uia_query_windows(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:queryWindows, queryparts)
      end

      # Invoke a Calabash query inside the UIAutomation Calabash engine - includes all UIAWindows.
      # Note that this traverses the UIA (accessibility) hierarchy.
      # @example uia equivalent of `identifier "button"`
      #   uia_names :button
      #   # returns
      #   [
      #     "Browse",
      #     "UINavigationBarBackIndicatorDefault.png",
      #     "16h",
      #     "reader postaction comment blue",
      #     "16h",
      #     "52",
      #     "17h",
      #     "10",
      #     "Reader",
      #     "Notifications",
      #     "Me",
      #     "New Post"
      #   ]
      # @param {Array} queryparts array of segments in the query, e.g., `:button, {marked:'Hello'}`
      # @return {Array<String>} "names" (accessibilityIdentifier) of UIAElements matching the query.
      def uia_names(*queryparts)
        #TODO escape '\n etc in query
        uia_handle_command(:names, queryparts)
      end

      # Advanced method used to invoke UIAutomation JavaScript methods on objects found via Calabash queries
      # @see #uia_query
      # @example Calling UIAButton.isVisible() - {https://developer.apple.com/library/ios/documentation/ToolsLanguages/Reference/UIAElementClassReference/UIAElement/UIAElement.html}
      #   uia_call [:button, {marked:'New Post'}], :isVisible
      # @example Advanced example that chains calls and uses arguments
      #   uia_call [:view, marked:'New Post'], {withName:"New Post"}, :toString, {charAt:0}
      #
      # @param {Array} args_arr array describing the query, e.g., `[:button, {marked:'foo'}]`
      # @param {Array} opts optional arguments specifying a chained sequence of method calls (see example)
      def uia_call(args_arr, *opts)
        uia_call_method(:queryEl, args_arr, *opts)
      end

      # Similar to `uia_call` but searches all windows
      # @see #uia_call
      def uia_call_windows(args_arr, *opts)
        uia_call_method(:queryElWindows, args_arr, *opts)
      end

      # @!visibility private
      def uia_tap(*queryparts)
        uia_handle_command(:tap, queryparts)
      end

      # @!visibility private
      def uia_tap_mark(mark)
        uia_handle_command(:tapMark, mark)
      end

      # @!visibility private
      def uia_tap_offset(offset)
        uia_handle_command(:tapOffset, offset)
      end

      # @!visibility private
      def uia_double_tap(*queryparts)
        uia_handle_command(:doubleTap, queryparts)
      end

      # @!visibility private
      def uia_double_tap_mark(mark)
        uia_double_tap(:view, {:marked => mark})
      end

      # @!visibility private
      def uia_double_tap_offset(offset)
        uia_handle_command(:doubleTapOffset, offset)
      end

      # @!visibility private
      def uia_two_finger_tap(*queryparts)
        uia_handle_command(:twoFingerTap, queryparts)
      end

      # @!visibility private
      def uia_two_finger_tap_offset(offset)
        uia_handle_command(:twoFingerTapOffset, offset)
      end

      # @!visibility private
      def uia_flick_offset(from, to)
        uia_handle_command(:flickOffset, from, to)
      end

      # @!visibility private
      def uia_touch_hold(duration, *queryparts)
        uia_handle_command(:touchHold, duration, queryparts)
      end

      # @!visibility private
      def uia_touch_hold_offset(duration, offset)
        uia_handle_command(:touchHoldOffset, duration, offset)
      end

      # @!visibility private
      def uia_pan(from_q, to_q)
        uia_handle_command(:pan, from_q, to_q)
      end

      # @!visibility private
      def uia_pan_offset(from, to, options)
        uia_handle_command(:panOffset, from, to, options)
      end

      # @!visibility private
      def uia_swipe(*queryparts)
        uia_handle_command(:swipe, queryparts)
      end

      # @!visibility private
      def uia_swipe_offset(offset, options)
        uia_handle_command(:swipeOffset, offset, options)
      end

      # @!visibility private
      def uia_pinch(*queryparts)
        uia_handle_command(:pinch, queryparts)
      end

      # @!visibility private
      def uia_pinch_offset(in_or_out, offset, duration)
        uia_handle_command(:pinchOffset, in_or_out, offset, duration)
      end

      # @!visibility private
      def uia_scroll_to(*queryparts)
        uia_handle_command(:scrollTo, queryparts)
      end

      # @!visibility private
      def uia_element_exists?(*queryparts)
        uia_handle_command(:elementExists, queryparts)
      end

      # @!visibility private
      def uia_element_does_not_exist?(*queryparts)
        uia_handle_command(:elementDoesNotExist, queryparts)
      end

      # @!visibility private
      def uia_screenshot(name)
        uia_handle_command(:screenshot, name)
      end

      # @!visibility private
      def uia_type_string(string, opt_text_before='', escape=true)
        if escape && string.index(/\\/)
          indexes = string.enum_for(:scan,/\\/).map { Regexp.last_match.begin(0) }
          indexes.reverse.each { |idx| string = string.insert(idx, '\\') }
        end
        res = uia_handle_command(:typeString, string, opt_text_before)
        status = res['status']
        if status.eql?('error')
          value = res['value']
          raise "could not type '#{string}' - '#{value}'"
        end
        status
      end

      # @!visibility private
      def uia_enter
        uia_handle_command(:enter)
      end

      # @!visibility private
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

      # @!visibility private
      def uia_send_app_to_background(secs)
        uia_handle_command(:deactivate, secs)
      end

      # @!visibility private
      def uia_call_method(cmd, args_arr, *opts)
        if opts.empty?
          return uia_handle_command(cmd, args_arr)
        end
        js_cmd = uia_serialize_command(cmd, args_arr)

        js_args = []
        opts.each do |invocation|
          js_args << case invocation
                       when Symbol
                         "#{invocation}()"
                       when Hash
                         m = invocation.keys.first
                         args = invocation[m]

                         if args.is_a?(Array)
                           serialized_args = (args.map &:to_json).join(',')
                         else
                           serialized_args = args.to_json
                         end


                         "#{m}(#{serialized_args})"
                       else
                         raise "Invalid invocation spec #{invocation}"
          end
        end
        command = "#{js_cmd}.#{js_args.join('.')}"
        if debug_logging?
          puts 'Sending UIA command'
          puts command
        end

        uia_result(uia(command))

      end

      # @!visibility private
      def uia_handle_command(cmd, *query_args)
        command = uia_serialize_command(cmd, *query_args)
        if debug_logging?
          puts 'Sending UIA command'
          puts command
        end
        s = uia(command)
        uia_result(s)
      end

      # @!visibility private
      def uia_serialize_command(cmd, *query_args)
        args = uia_serialize_arguments(query_args)
        %Q[uia.#{cmd}(#{args.join(', ')})]
      end

      # @!visibility private
      def uia_serialize_arguments(args)
        args.map do |part|
          uia_serialize_argument(part)
        end
      end

      # @!visibility private
      def uia_serialize_argument(part)
        if part.is_a?(String)
          "'#{escape_uia_string(part)}'"
        else
          "'#{escape_uia_string(part.to_edn)}'"
        end
      end

      # @!visibility private
      def escape_uia_string(string)
        #TODO escape '\n in query
        escape_quotes string
      end

      # <b>DEPRECATED:</b> Use <tt>uia("...javascript..", options)</tt> instead.
      # deprecated because the method signature is poor
      # @!visibility private
      def send_uia_command(opts ={})

        # TODO formally deprecate send_uia_command with _deprecated function
        #cmd = opts[:command]
        #new_opts = cmd.select{|x| x != :command}
        #_deprecated('0.9.163',
        #            "use 'uia(#{cmd}, #{new_opts})' instead",
        #            :warn)

        uia(opts[:command], opts)
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

      def uia_result(s)
        if debug_logging?
          puts 'Result'
          p s
        end
        if s['status'] == 'success'
          s['value']
        else
          s
        end
      end



    end
  end
end

require 'httpclient'
require 'json'
require 'geocoder'
require 'calabash-cucumber/uia'
require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/connection'
require 'calabash-cucumber/connection_helpers'
require 'calabash-cucumber/query_helpers'
require 'calabash-cucumber/failure_helpers'
require 'calabash-cucumber/status_bar_helpers'
require 'calabash-cucumber/rotation_helpers'
require 'calabash-cucumber/map'

module Calabash
  module Cucumber

    # A collection of methods that provide the core calabash behaviors.
    module Core

      require "calabash-cucumber/map"
      include Calabash::Cucumber::EnvironmentHelpers
      include Calabash::Cucumber::ConnectionHelpers
      include Calabash::Cucumber::QueryHelpers
      include Calabash::Cucumber::FailureHelpers
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::StatusBarHelpers
      include Calabash::Cucumber::RotationHelpers

      require "calabash-cucumber/keyboard_helpers"
      include Calabash::Cucumber::KeyboardHelpers

      # @!visibility private
      # @deprecated Use Cucumber's step method.
      #
      # Using `step` is not considered a best practice.
      #
      # Used in older cucumber versions that didn't have the `step` method.
      #
      # Shouldn't be used anymore.
      def macro(txt)
        if self.respond_to? :step
          step(txt)
        else
          Then txt
        end
      end

      # Prints a blue warning message.
      # @param [String] msg the message to print
      # @return [void]
      def calabash_warn(msg)
        require "run_loop/logging"
        RunLoop.log_warn(msg)
      end

      # Prints a green info message.
      # @param [String] msg the message to print
      # @return [void]
      def calabash_info(msg)
        require "run_loop/logging"
        RunLoop.log_info2(msg)
      end

      # Prints a deprecated message that includes the line number.
      #
      # @param [String] version indicates when the feature was deprecated
      # @param [String] msg deprecation message (possibly suggesting alternatives)
      # @param [Symbol] type { :warn | :pending } - :pending will raise a
      #   cucumber pending error
      # @return [void]
      def deprecated(version, msg, type)
        allowed = [:pending, :warn]
        unless allowed.include?(type)
          raise ArgumentError, "Expected type '#{type}' to be one of #{allowed.join(", ")}"
        end

        stack = Kernel.caller(0, 6)[1..-1].join("\n")

        msg = "deprecated '#{version}' - #{msg}\n#{stack}"

        if type.eql?(:pending)
          pending(msg)
        else
          calabash_warn(msg)
        end
      end

      # The core method for querying into the current visible view
      # of the app under test. The query method takes as first parameter
      # a String `:uiquery`. This string must follow the query syntax
      # described in:
      # {http://developer.xamarin.com/guides/testcloud/calabash/calabash-query-syntax/ Query Syntax}.
      #
      # Optionally `query` takes a variable number of "invocation" arguments
      # (`args` below). # If called with an empty list of `*args`, `query`
      # will find the views specified by `uiquery` and return a serialized view
      # (see Examples below).
      #
      # If `*args` are given, then they should describe a valid selector invocation
      # on the queried views. For example `query('UILabel', :text)` would perform
      # the `:text` selector on all visible `UILabel` objects and return those as
      # an Array of Strings.
      #
      # The `query` method provide a powerful mechanism for `querying` app view state
      # and can be used to reflectively call arbitrary methods on objects reachable
      # from the view. For a full specification of `*args` see
      # {http://developer.xamarin.com/guides/testcloud/calabash/calabash-query-syntax/ Query Syntax}.
      #
      # @example Basic view query
      #   irb(main):009:0> query("UITabBarButton index:0")
      #   [
      #       [0] {
      #             "class" => "UITabBarButton",
      #       "id" => nil,
      #       "rect" => {
      #           "center_x" => 40,
      #           "y" => 520,
      #           "width" => 76,
      #           "x" => 2,
      #           "center_y" => 544,
      #           "height" => 48
      #      },
      #       "frame" => {
      #           "y" => 1,
      #           "width" => 76,
      #           "x" => 2,
      #           "height" => 48
      #       },
      #       "label" => "Reader",
      #       "description" => "<UITabBarButton: 0xdabb510; frame = (2 1; 76 48); opaque = NO; layer = <CALayer: 0xdabd8e0>>"
      #     }
      #   ]
      # @example Simple selector
      #   irb(main):010:0> query("UILabel", :text)
      #   [
      #       [0] "The Ugly Volvo",
      #       [1] "Why Having a Baby Reminds me of Garfield Minus Garfield",
      #       [2] "I love the site Garfield Minus Garfield. If you don’t know the site Garfield minus Garfield  it’s a website run by a guy named Dan Walsh who takes Garfield comic strips and digitally erases Garfield from them.   more",
      #       [3] "Freshly Pressed",
      #       [4] "Reader",
      #       [5] "Notifications",
      #       [6] "Me"
      #   ]
      # @param [String] uiquery the query to perform. Must follow the query syntax:
      #   {http://developer.xamarin.com/guides/testcloud/calabash/calabash-query-syntax/ Query Syntax}.
      # @param [Array] args optional var-args list describing a chain of method selectors.
      #   Full details {http://developer.xamarin.com/guides/testcloud/calabash/calabash-query-syntax/ Query Syntax}.
      def query(uiquery, *args)
        Map.map(uiquery, :query, *args)
      end

      # Shorthand alias for `query`.
      # @see #query
      # @!visibility private
      def q(uiquery, *args)
        query(uiquery, *args)
      end

      # Causes all views matched by the `uiquery` to briefly change colors making
      # them visually identifiable.
      #
      # @param [String] uiquery a query specifying which objects to flash
      # @param [Array] args argument is ignored and should be deprecated
      # @return [Array] an array of that contains all the view matched.
      def flash(uiquery, *args)
        # todo deprecate the *args argument in the flash method
        # todo :flash operation should return views as JSON objects
        Map.map(uiquery, :flash, *args).compact
      end

      # Returns the version of the running calabash server.
      # @return [String] version of the running calabash server.
      def server_version
        JSON.parse(http(:path => 'version'))
      end

      # Returns the version of the loaded Calabash library.
      # @see Calabash::Cucumber::VERSION
      # @return [String] the version of the loaded Calabash library.
      def client_version
        Calabash::Cucumber::VERSION
      end

      # Rotates the home button to a position relative to the status bar.
      #
      # @example portrait
      #  rotate_home_button_to :down
      #
      # @example upside down
      #  rotate_home_button_to :up
      #
      # @example landscape with left home button AKA: _right_ landscape
      #  rotate_home_button_to :left
      #
      # @example landscape with right home button AKA: _left_ landscape
      #  rotate_home_button_to :right
      #
      # Refer to Apple's documentation for clarification about left vs.
      # right landscape orientations.
      #
      # For legacy support the `dir` argument can be a String or Symbol.
      # Please update your code to pass a Symbol.
      #
      # For legacy support `:top` and `top` are synonyms for `:up`.
      # Please update your code to pass `:up`.
      #
      # For legacy support `:bottom` and `bottom` are synonyms for `:down`.
      # Please update your code to pass `:down`.
      #
      # @param [Symbol] position The position of the home button after the rotation.
      #  Can be one of `{:down | :left | :right | :up }`.
      #
      # @note A rotation will only occur if your view controller and application
      #  support the target orientation.
      #
      # @return [Symbol] The position of the home button relative to the status
      #  bar when all rotations have been completed.
      def rotate_home_button_to(position)

        normalized_symbol = expect_valid_rotate_home_to_arg(position)
        current_orientation = status_bar_orientation.to_sym

        return current_orientation if current_orientation == normalized_symbol

        launcher.gesture_performer.send(:rotate_home_button_to, normalized_symbol)
      end

      # Rotates the device in the direction indicated by `direction`.
      #
      # @example rotate left
      #  rotate :left
      #
      # @example rotate right
      #  rotate :right
      #
      # @param [Symbol] direction The direction to rotate. Can be :left or :right.
      #
      # @return [Symbol] The position of the home button relative to the status
      #   bar after the rotation.  Will be one of `{:down | :left | :right | :up }`.
      # @raise [ArgumentError] If direction is not :left or :right.
      def rotate(direction)
        as_symbol = direction.to_sym

        if as_symbol != :left && as_symbol != :right
          raise ArgumentError,
                "Expected '#{direction}' to be :left or :right"
        end

        launcher.gesture_performer.send(:rotate, as_symbol)
      end

      # Performs the `tap` gesture on the (first) view that matches
      # query `uiquery`. Note that `touch` assumes the view is visible and not
      # animating. If the view is not visible `touch` will fail. If the view is
      # animating `touch` will *silently* fail.
      #
      # By default, taps the center of the view.
      # @see Calabash::Cucumber::WaitHelpers#wait_tap
      # @see Calabash::Cucumber::Operations#tap_mark
      # @see #tap_point
      #
      # @param {String} uiquery query describing view to tap. If this value is
      #  `nil` then an :offset must be passed as an option.  This can be used
      #  to tap a specific coordinate.
      # @param {Hash} options option for modifying the details of the touch
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #  Offset supports an `:x` and `:y` key and causes the touch to be offset
      #  with `(x,y)` relative to the center.
      #
      # @return {Array<Hash>} array containing the serialized version of the
      # tapped view.
      #
      # @raise [RuntimeError] If query is non nil and matches no views.
      # @raise [ArgumentError] If query is nil and there is no :offset in the
      #  the options.  The offset must contain both an :x and :y value.
      def touch(uiquery, options={})
        if uiquery.nil?
          offset = options[:offset]

          if !(offset && offset[:x] && offset[:y])
            raise ArgumentError, %Q[
If query is nil, there must be a valid offset in the options.

Expected: options[:offset] = {:x => NUMERIC, :y => NUMERIC}
  Actual: options[:offset] = #{offset ? offset : "nil"}

            ]
          end
        end
        query_action_with_options(:touch, uiquery, options)
      end

      # Performs the `tap` gesture on an absolute coordinate.
      # @see Calabash::Cucumber::WaitHelpers#wait_tap
      # @see Calabash::Cucumber::Operations#tap_mark
      # @see #touch
      # @param {Numeric} x x-coordinate to tap
      # @param {Numeric} y y-coordinate to tap
      # @return {Boolean} `true`
      def tap_point(x,y)
        touch(nil, offset: {x:x, y:y})
      end

      # Performs the "double tap" gesture on the (first) view that matches query `uiquery`.
      #
      # @note This assumes the view is visible and not animating.
      #
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      #
      # By default, taps the center of the view.
      # @example
      #   double_tap "view marked:'Third'", offset:{x:100}
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} options option for modifying the details of the touch
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @return {Array<Hash>} array containing the serialized version of the tapped view.
      def double_tap(uiquery, options={})
        query_action_with_options(:double_tap, uiquery, options)
      end

      # Performs the "two-finger tap" gesture on the (first) view that matches
      # query `uiquery`.
      #
      # @note This assumes the view is visible and not animating.
      #
      # If the view is not visible it will fail with an error. If the view is
      # animating it will *silently* fail.
      #
      # By default, taps the center of the view.
      #
      # @example
      #   two_finger_tap "view marked:'Third'", offset:{x:100}
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #  Offset supports an `:x` and `:y` key and causes the touch to be offset
      #  with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @return {Array<Hash>} array containing the serialized version of the
      #  tapped view.
      def two_finger_tap(uiquery,options={})
        query_action_with_options(:two_finger_tap, uiquery, options)
      end

      # Performs the "long press" or "touch and hold" gesture on the (first)
      # view that matches query `uiquery`.
      #
      # @note This assumes the view is visible and not animating.
      #
      # If the view is not visible it will fail with an error. If the view is
      # animating it will *silently* fail.
      #
      # By default, the gesture starts at the center of the view.
      #
      # @example
      #   touch_hold "webView css:'input'", duration:10, offset:{x: -40}
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #   Offset supports an `:x` and `:y` key and causes the touch to be offset
      #   with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option options {Numeric} :duration (3) duration of the 'hold'.
      # @return {Array<Hash>} array containing the serialized version of the
      #  touched view.
      def touch_hold(uiquery, options={})
        query_action_with_options(:touch_hold, uiquery, options)
      end

      # Performs a "swipe" gesture.
      #
      # @example
      #
      #   # Swipe left on first view match by "*"
      #   swipe(:left)
      #
      #   # Swipe up on 'my scroll view'
      #   swipe(:up, {:query => "* marked:'my scroll view'"})
      #
      # @param {String, Symbol} direction The direction to swipe
      # @param {Hash} options Options for modifying the details of the swipe.
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #  Offset supports an `:x` and `:y` key and causes the touch to be
      #  offset with `(x,y)` relative to the center.
      # @option options {String} :query (nil) If specified, the swipe will be
      #  made on the first view matching this query.  If this option is nil
      #  (the default), the swipe will happen on the first view matched by "*".
      # @option options [Symbol] :force (normal) Indicates the force of the
      #  swipe.  Valid values are :strong, :normal, :light.
      #
      # @return {Array<Hash>,String} An array with one element; the view that
      #  was swiped.
      #
      # @raise [ArgumentError] If :force is invalid.
      # @raise [ArgumentError] If direction is invalid
      def swipe(direction, options={})
        merged_options = {
          :query => nil,
          :force => :normal
        }.merge(options)

        merged_options[:direction] = direction.to_sym

        if ![:up, :down, :left, :right].include?(merged_options[:direction])
          raise ArgumentError, %Q[
Invalid direction argument: '#{direction}'.

Valid directions are: :up, :down, :left, and :right

]
        end

         if ![:light, :strong, :normal].include?(merged_options[:force])
           raise ArgumentError, %Q[
Invalid force option: '#{merged_options[:force]}'.

Valid forces are: :strong, :normal, :light

]
         end

        launcher.gesture_performer.swipe(merged_options)
      end

      # Performs the "flick" gesture on the first view that matches `uiquery`.
      #
      # If the view is not visible it will fail with an error.
      #
      # If the view is animating it will *silently* fail.
      #
      # By default, the gesture starts at the center of the view and "flicks"
      # according to `delta`.
      #
      # A flick is a swipe with velocity.
      #
      # @example
      #   # Flick left: move screen to the right
      #   delta = {:x => -124.0, :y => 0.0}
      #
      #   # Flick right: move screen to the left
      #   delta = {:x => 124.0, :y => 0.0}
      #
      #   # Flick up: move screen to the bottom
      #   delta = {:x => 0, :y => -124.0}
      #
      #   # Flick down: move screen to the top
      #   delta = {:x => 0, :y => 124.0}
      #
      #   # Flick up and to the left: move the screen to the lower right corner
      #   delta = {:x => -88, :y => -88}
      #
      #   flick("MKMapView", delta)
      #
      # @param {String} uiquery query describing view to flick.
      # @param {Hash} delta coordinate describing the direction to flick
      # @param {Hash} options option for modifying the details of the flick.
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #   Offset supports an `:x` and `:y` key and causes the first touch to be
      #   offset with `(x,y)` relative to the center.
      # @return {Array<Hash>} array containing the serialized version of the touched view.
      #
      # @raise [ArgumentError] If query is nil.
      def flick(uiquery, delta, options={})
        if uiquery.nil?
          raise ArgumentError, "Query argument cannot be nil"
        end

        merged_options = {
          :delta => delta
        }.merge(options)

        query_action_with_options(:flick, uiquery, merged_options)
      end

      # Performs the pan gesture between two coordinates.
      #
      # Swipes, scrolls, drag-and-drop, and flicks are all pan gestures.
      #
      # @example
      #   # Reorder table view rows.
      #   q1="* marked:'Reorder Apple'"
      #   q2="* marked:'Reorder Google'"
      #   pan q1, q2, duration:4
      #
      # @param {String} from_query query describing view to start the gesture
      # @param {String} to_query query describing view to end the gesture
      # @option options {Hash} :offset (nil) optional offset to touch point.
      #  Offset supports an `:x` and `:y` key and causes the pan to be offset
      #  with `(x,y)` relative to the center.
      # @option options {Numeric} :duration (1.0) duration of the 'pan'.  The
      #  minimum value of pan in UIAutomation is 0.5.  For DeviceAgent, the
      #  duration must be > 0.
      # @return {Array<Hash>} array containing the serialized version of the
      #  touched views.  The first element is the first view matched by
      #  the from_query and the second element is the first view matched by
      #  the to_query.
      #
      # @raise [ArgumentError] If duration is < 0.5 for UIAutomation and <= 0
      #  for DeviceAgent.
      def pan(from_query, to_query, options={})
        merged_options = {
          # Minimum value for UIAutomation is 0.5.
          # DeviceAgent duration must be > 0.
          :duration => 1.0
        }.merge(options)

        duration = merged_options[:duration]

        if uia_available? && duration < 0.5
          raise ArgumentError, %Q[
Invalid duration: #{duration}

The minimum duration is 0.5

]
        elsif duration <= 0.0
          raise ArgumentError, %Q[
Invalid duration: #{duration}

The minimum duration is 0.0.

]
        end

        launcher.gesture_performer.pan(from_query, to_query, merged_options)
      end

      # Performs the pan gesture between two coordinates.
      #
      # Swipes, scrolls, drag-and-drop, and flicks are all pan gestures.
      #
      # @example
      #   # Pan to go back in UINavigationController
      #   element = query("*").first
      #   y = element["rect"]["center_y"]
      #   pan_coordinates({10, y}, {160, y})
      #
      #   # Pan to reveal Today and Notifications
      #   element = query("*").first
      #   x = element["rect"]["center_x"]
      #   pan_coordinates({x, 0}, {x, 240})
      #
      #   # Pan to reveal Control Panel
      #   element = query("*").first
      #   x = element["rect"]["center_x"]
      #   y = element["rect"]["height"]
      #   pan_coordinates({x, height}, {x, 240})
      #
      # @param {String} from_point where to start the pan.
      # @param {String} to_query where to end the pan.
      # @option options {Numeric} :duration (1.0) duration of the 'pan'.  The
      #  minimum value of pan in UIAutomation is 0.5.  For DeviceAgent, the
      #  duration must be > 0.
      #
      # @raise [ArgumentError] If duration is < 0.5 for UIAutomation and <= 0
      #  for DeviceAgent.
      def pan_coordinates(from_point, to_point, options={})
        merged_options = {
          # Minimum value for UIAutomation is 0.5.
          # DeviceAgent duration must be > 0.
          :duration => 1.0
        }.merge(options)

        duration = merged_options[:duration]

        if uia_available? && duration < 0.5
          raise ArgumentError, %Q[
Invalid duration: #{duration}

The minimum duration is 0.5

]
        elsif duration <= 0.0
          raise ArgumentError, %Q[
Invalid duration: #{duration}

The minimum duration is 0.0.

]
        end

        launcher.gesture_performer.pan_coordinates(from_point, to_point,
                                                   merged_options)
      end

      # Performs a "pinch" gesture.
      # By default, the gesture starts at the center of the screen.
      # @todo `pinch` is an old style API which doesn't take a query as its first argument. We should migrate this.
      # @example
      #   pinch :out
      # @example
      #   pinch :in, query:"MKMapView", offset:{x:42}
      # @param {String} in_out the direction to pinch ('in' or 'out') (symbols can also be used).
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option options {String} :query (nil) if specified, the pinch will be made relative to this query.
      # @return {Array<Hash>,String} array containing the serialized version of the touched view if `options[:query]` is given.
      def pinch(in_out, options={})
        launcher.gesture_performer.pinch(in_out.to_sym,options)
      end

      # Use keyboard to enter a character.
      #
      # @note
      #  There are several special 'characters', some of which do not appear on
      #  all keyboards; e.g. `Delete`, `Return`.
      #
      # @see #keyboard_enter_text
      #
      # @note
      #  You should prefer to call `keyboard_enter_text`.
      #
      # @raise [RuntimeError] If there is no visible keyboard
      # @raise [RuntimeError] If the keyboard (layout) is not supported
      #
      # @param [String] char The character to type
      # @param [Hash] options Controls the behavior of the method.
      # @option opts [Numeric] :wait_after_char (0.05) How long to sleep after
      #  typing a character.
      def keyboard_enter_char(char, options={})
        expect_keyboard_visible!

        default_opts = {:wait_after_char => 0.05}
        merged_options = default_opts.merge(options)

        special_char = launcher.gesture_performer.char_for_keyboard_action(char)

        if special_char
          launcher.gesture_performer.enter_char_with_keyboard(special_char)
        elsif char.length == 1
          launcher.gesture_performer.enter_char_with_keyboard(char)
        else
          raise ArgumentError, %Q[
Expected '#{char}' to be a single character or a special string like:

* Return
* Delete

To type strings with more than one character, use keyboard_enter_text.
]
        end

        duration = merged_options[:wait_after_char]
        if duration > 0
          Kernel.sleep(duration)
        end

        []
      end

      # Touches the keyboard action key.
      #
      # The action key depends on the keyboard.  Some examples include:
      #
      # * Return
      # * Next
      # * Go
      # * Join
      # * Search
      #
      # @note
      #  Not all keyboards have an action key.  For example, numeric keyboards
      #  do not have an action key.
      #
      # @raise [RuntimeError] If the keyboard is not visible.
      def tap_keyboard_action_key
        expect_keyboard_visible!
        launcher.gesture_performer.tap_keyboard_action_key
      end

      # Touches the keyboard delete key.
      #
      # @raise [RuntimeError] If the keyboard is not visible.
      def tap_keyboard_delete_key
        expect_keyboard_visible!
        launcher.gesture_performer.tap_keyboard_delete_key
      end

      # Uses the keyboard to enter text.
      #
      # @param [String] text the text to type.
      # @raise [RuntimeError] If the keyboard is not visible.
      def keyboard_enter_text(text)
        expect_keyboard_visible!
        existing_text = text_from_first_responder
        escaped = existing_text.gsub("\n","\\n")
        launcher.gesture_performer.enter_text_with_keyboard(text, escaped)
      end

      # @!visibility private
      #
      # Enters text into view identified by a query
      #
      # This behavior of this method depends on the Gesture::Performer
      # implementation.
      #
      # ### UIAutomation
      #
      # defaults to calling 'setValue' in UIAutomation on the UITextField or
      # UITextView.  This is fast, but in some cases might result in slightly
      # different behaviour than using `keyboard_enter_text`.
      # To force use of #keyboard_enter_text option :use_keyboard
      #
      # ### DeviceAgent
      #
      # This method calls #keyboard_enter_text regardless of the options passed.
      #
      # @param [String] uiquery the element to enter text into
      # @param [String] text the text to enter
      # @param [Hash] options controls details of text entry
      # @option options [Boolean] :use_keyboard (false) use the iOS keyboard
      #   to enter each character separately
      # @option options [Boolean] :wait (true) call wait_for_element_exists with
      #   uiquery
      # @option options [Hash] :wait_options ({}) if :wait pass this as options
      #   to wait_for_element_exists
      def enter_text_in(uiquery, text, options = {})
        default_opts = {:use_keyboard => false, :wait => true, :wait_options => {}}
        options = default_opts.merge(options)
        wait_for_element_exists(uiquery, options[:wait_options]) if options[:wait]
        touch(uiquery, options)
        wait_for_keyboard
        if options[:use_keyboard]
          keyboard_enter_text(text)
        else
          fast_enter_text(text)
        end
      end

      alias_method :enter_text, :enter_text_in

      # @!visibility private
      #
      # Enters text into current text input field
      #
      # This behavior of this method depends on the Gesture::Performer
      # implementation.
      #
      # ### UIAutomation
      #
      # defaults to calling 'setValue' in UIAutomation on the UITextField or
      # UITextView.  This is fast, but in some cases might result in slightly
      # different behaviour than using `keyboard_enter_text`.
      # To force use of #keyboard_enter_text option :use_keyboard
      #
      # ### DeviceAgent
      #
      # This method calls #keyboard_enter_text.
      #
      # @param [String] text the text to enter
      def fast_enter_text(text)
        expect_keyboard_visible!
        launcher.gesture_performer.fast_enter_text(text)
      end

      # Dismisses a iPad keyboard by touching the 'Hide keyboard' button and waits
      # for the keyboard to disappear.
      #
      # @note
      #  the dismiss keyboard key does not exist on the iPhone or iPod
      #
      # @raise [RuntimeError] If the device is not an iPad
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] If the keyboard does
      #  not disappear.
      def dismiss_ipad_keyboard
        # TODO Maybe relax this restriction; turn it into a nop on iPhones?
        # TODO Support iPhone 6 Plus form factor dismiss keyboard key.
        if device_family_iphone?
          screenshot_and_raise %Q[
There is no Hide Keyboard key on an iPhone.

Use `ipad?` to branch in your test.

]
        end

        expect_keyboard_visible!

        launcher.gesture_performer.dismiss_ipad_keyboard

        wait_for_no_keyboard
      end

      # Scroll a scroll view in a direction. By default scrolls half the frame size.
      # @example
      #   scroll("UITableView", :down)
      # @note this is implemented by calling the Obj-C `setContentOffset:animated:` method and can do things users cant.
      #
      # @param {String} uiquery query describing view scroll (should be  UIScrollView or a web view).
      # @param [Symbol] direction The direction to scroll. Valid directions are:
      #   :up, :down, :left, and :right
      def scroll(uiquery, direction)
        allowed_directions = [:up, :down, :left, :right]
        dir_symbol = direction.to_sym
        unless allowed_directions.include?(dir_symbol)
          raise ArgumentError, "Expected '#{direction} to be one of #{allowed_directions}"
        end

        views_touched = Map.map(uiquery, :scroll, dir_symbol)
        msg = "could not find view to scroll: '#{uiquery}', args: #{dir_symbol}"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Scroll a table view to a row. Table view should have only one section.
      # @see #scroll_to_cell
      # @example
      #   scroll_to_row "UITableView", 2
      # @note this is implemented by calling the Obj-C `scrollToRowAtIndexPath:atScrollPosition:animated:` method
      #   and can do things users cant.
      #
      # @param {String} uiquery query describing view scroll (should be  UIScrollView or a web view).
      def scroll_to_row(uiquery, number)
        views_touched = Map.map(uiquery, :scrollToRow, number)
        msg = "unable to scroll: '#{uiquery}' to: #{number}"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Scroll a table view to a section and row. Table view can have multiple sections.
      #
      # @todo should expose a non-option first argument query and required parameters `section`, `row`
      #
      # @see #scroll_to_row
      # @example
      #   scroll_to_cell query:"UITableView", row:4, section:0, animate: false
      # @note this is implemented by calling the Obj-C `scrollToRowAtIndexPath:atScrollPosition:animated:` method
      #   and can do things users cant.
      #
      # @param {Hash} options specifies details of the scroll
      # @option options {String} :query ('tableView') query specifying which table view to scroll
      # @option options {Fixnum} :section section to scroll to
      # @option options {Fixnum} :row row to scroll to
      # @option options {String} :scroll_position position to scroll to
      # @option options {Boolean} :animated (true) animate or not
      def scroll_to_cell(options={:query => 'tableView',
                                  :row => 0,
                                  :section => 0,
                                  :scroll_position => :top,
                                  :animate => true})
        uiquery = options[:query] || 'tableView'
        row = options[:row]
        sec = options[:section]
        if row.nil? or sec.nil?
          raise 'You must supply both :row and :section keys to scroll_to_cell'
        end

        args = []
        if options.has_key?(:scroll_position)
          args << options[:scroll_position]
        else
          args << 'top'
        end
        if options.has_key?(:animate)
          args << options[:animate]
        end
        views_touched = Map.map(uiquery, :scrollToRow, row.to_i, sec.to_i, *args)
        msg = "unable to scroll: '#{uiquery}' to '#{options}'"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Scrolls to a mark in a UITableView.
      #
      # @example Scroll to the top of the item with the given mark.
      #  scroll_to_row_with_mark('settings', {:scroll_position => :top})
      #
      # @example Scroll to the bottom of the item with the given mark.
      #  scroll_to_row_with_mark('about', {:scroll_position => :bottom})
      #
      # @param [String] mark an accessibility `{label | identifier}` or text in
      #  or on the row
      # @param [Hash] options controls the query and and scroll behavior
      #
      # @option options [String] :query ('tableView')
      #  the query that should be used to location the table
      # @option options [Symbol] :scroll_position (:middle)
      #  the table position to scroll the row to - allowed values
      #  `{:middle | :top | :bottom}`
      # @option options [Boolean] :animate (true)
      #  should the scrolling be animated
      #
      # @raise [RuntimeError] if the scroll cannot be performed
      # @raise [RuntimeError] if the mark is nil
      # @raise [RuntimeError] if the table query finds no table view
      # @raise [RuntimeError] if the scroll position is invalid
      def scroll_to_row_with_mark(mark, options={:query => 'tableView',
                                                 :scroll_position => :middle,
                                                 :animate => true})
        if mark.nil?
          screenshot_and_raise 'mark argument cannot be nil'
        end

        uiquery = options[:query] || 'tableView'

        args = []
        if options.has_key?(:scroll_position)
          args << options[:scroll_position]
        else
          args << 'middle'
        end
        if options.has_key?(:animate)
          args << options[:animate]
        end

        views_touched = Map.map(uiquery, :scrollToRowWithMark, mark, *args)
        msg = options[:failed_message] || "Unable to scroll: '#{uiquery}' to: #{options}"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Scrolls to an item in a section of a UICollectionView.
      #
      # @note item and section are zero-indexed
      #
      # @example Scroll to item 0 in section 2 to top.
      #  scroll_to_collection_view_item(0, 2, {:scroll_position => :top})
      #
      # @example Scroll to item 5 in section 0 to bottom.
      #  scroll_to_collection_view_item(5, 0, {:scroll_position => :bottom})
      #
      # @example The following are the allowed :scroll_position values.
      #  {:top | :center_vertical | :bottom | :left | :center_horizontal | :right}
      #
      # @param [Integer] item the index of the item to scroll to
      # @param [Integer] section the section of the item to scroll to
      # @param [Hash] opts options for controlling the collection view query
      #  and scroll behavior
      #
      # @option opts [String] :query ('collectionView')
      #  the query that is used to identify which collection view to scroll
      #
      # @option opts [Symbol] :scroll_position (top)
      #  the position in the collection view to scroll the item to
      #
      # @option opts [Boolean] :animate (true)
      #  should the scrolling be animated
      #
      # @option opts [String] :failed_message (nil)
      #  a custom error message to display if the scrolling fails - if not
      #  specified, a generic failure will be displayed
      #
      # @raise [RuntimeError] if the scroll cannot be performed
      # @raise [RuntimeError] :query finds no collection view
      # @raise [RuntimeError] the collection view does not contain a cell at item/section
      # @raise [RuntimeError] :scroll_position is invalid
      def scroll_to_collection_view_item(item, section, opts={})
        default_options = {:query => 'collectionView',
                           :scroll_position => :top,
                           :animate => true,
                           :failed_message => nil}
        opts = default_options.merge(opts)
        uiquery = opts[:query]

        scroll_position = opts[:scroll_position]
        candidates = [:top, :center_vertical, :bottom, :left, :center_horizontal, :right]
        unless candidates.include?(scroll_position)
          raise "scroll_position '#{scroll_position}' is not one of '#{candidates}'"
        end

        animate = opts[:animate]

        views_touched = Map.map(uiquery, :collectionViewScroll,
                                item.to_i, section.to_i,
                                scroll_position, animate)

        if opts[:failed_message]
          msg = opts[:failed_message]
        else
          msg = "unable to scroll: '#{uiquery}' to item '#{item}' in section '#{section}'"
        end

        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Scrolls to mark in a UICollectionView.
      #
      # @example Scroll to the top of the item with the given mark.
      #  scroll_to_collection_view_item_with_mark('cat', {:scroll_position => :top})
      #
      # @example Scroll to the bottom of the item with the given mark.
      #  scroll_to_collection_view_item_with_mark('dog', {:scroll_position => :bottom})
      #
      # @example The following are the allowed :scroll_position values.
      #  {:top | :center_vertical | :bottom | :left | :center_horizontal | :right}
      #
      # @param [String] mark an accessibility `{label | identifier}` or text in
      #  or on the item
      # @param [Hash] opts options for controlling the collection view query
      #  and scroll behavior
      #
      # @option opts [String] :query ('collectionView')
      #   the query that is used to identify which collection view to scroll
      # @option opts [Symbol] :scroll_position (:top)
      #   the position in the collection view to scroll the item to
      # @option opts [Boolean] :animate (true) should the scroll
      #   be animated
      # @option opts [String] :failed_message (nil)
      #  a custom error message to display if the scrolling fails - if not
      #  specified, a generic failure will be displayed
      #
      # @raise [RuntimeError] if the scroll cannot be performed
      # @raise [RuntimeError] if the mark is nil
      # @raise [RuntimeError] :query finds no collection view
      # @raise [RuntimeError] the collection view does not contain a cell
      #  with the mark
      # @raise [RuntimeError] :scroll_position is invalid
      def scroll_to_collection_view_item_with_mark(mark, opts={})
        default_options = {:query => 'collectionView',
                           :scroll_position => :top,
                           :animate => true,
                           :failed_message => nil}
        opts = default_options.merge(opts)
        uiquery = opts[:query]

        if mark.nil?
          raise 'mark argument cannot be nil'
        end

        args = []
        scroll_position = opts[:scroll_position]
        candidates = [:top, :center_vertical, :bottom, :left, :center_horizontal, :right]
        unless candidates.include?(scroll_position)
          raise "scroll_position '#{scroll_position}' is not one of '#{candidates}'"
        end

        args << scroll_position
        args << opts[:animate]

        views_touched = Map.map(uiquery, :collectionViewScrollToItemWithMark,
                                mark, *args)

        msg = opts[:failed_message] || "Unable to scroll: '#{uiquery}' to cell with mark: '#{mark}' with #{opts}"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Sends the app to the background.
      #
      # Sending the app to the background for more than 60 seconds may
      # cause unpredictable results.
      #
      # @param [Numeric] seconds How long to send the app to the background.
      # @raise [ArgumentError] if `seconds` argument is < 1.0
      def send_app_to_background(seconds)
        if seconds < 1.0
          raise ArgumentError, "Seconds '#{seconds}' must be >= 1.0"
        end

        parameters = {
          :duration => seconds
        }

        begin
          body = http({:method => :post, :path => "suspend"}, parameters)
          result = response_body_to_hash(body)
        rescue RuntimeError => e
          raise RuntimeError, e
        end

        if result["outcome"] != "SUCCESS"
          raise RuntimeError,
            %Q{Could not send app to background:
 reason => '#{result["reason"]}'
details => '#{result["details"]}'
            }
        end
        result["results"]
      end

      # Cause the device to shake.
      #
      # @param [Numeric] seconds How long to shake the device
      # @raise [ArgumentError] if `seconds` argument is <= 0.0
      def shake(seconds)
        if seconds <= 0.0
          raise ArgumentError, "Seconds '#{seconds}' must be >= 0.0"
        end

        parameters = {
          :duration => seconds
        }

        begin
          body = http({:method => :post, :path => "shake"}, parameters)
          result = response_body_to_hash(body)
        rescue RuntimeError => e
          raise RuntimeError, e
        end

        if result["outcome"] != "SUCCESS"
          raise RuntimeError,
%Q{Could not shake the device:
 reason => '#{result["reason"]}'
details => '#{result["details"]}'
            }
        end
        result["results"]
      end

      # Simulates gps location of the device/simulator.
      # @note Seems UIAutomation is broken here on physical devices on iOS 7.1
      # @example
      #   set_location place:'Tower of London'
      # @param {Hash} options specifies which location to simulate
      # @option options {String} :place a description of a place (resolved via Google maps api), e.g. "Tower of London"
      # @option options {Numeric} :latitude latitude of a gps coordinate (same coordinate system as Google maps)
      # @option options {Numeric} :longitude longitude of a gps coordinate (same coordinate system as Google maps)
      def set_location(options)
        if uia_available?
          uia_set_location(options)
        else
          if options[:place]
            res = location_for_place(options[:place])
            lat = res.latitude
            lon = res.longitude
          else
            lat = options[:latitude]
            lon = options[:longitude]
          end
          body_data = {:action => :change_location,
                       :latitude => lat,
                       :longitude => lon}

          body = http({:method => :post, :path => 'location'}, body_data)

          res = JSON.parse(body)
          if res['outcome'] != 'SUCCESS'
            screenshot_and_raise "Set location change failed, for #{lat}, #{lon} (#{body})."
          end
          res['results']

        end
      end

      # Returns a geo-location search result (via Google). Requires internet.
      # @param {String} place a description of the place to search for
      # @return {Geocoder::Result::Google} result of the search - see {http://www.rubygeocoder.com/}.
      def location_for_place(place)
        search_results = locations_for_place(place)
        raise "Got no results for #{place}" if search_results.empty?
        search_results.first
      end

      # @!visibility private
      def locations_for_place(place)
        Geocoder.search(place)
      end

      # @!visibility private
      def picker(opts={:query => 'pickerView', :action => :texts})
        raise 'Not implemented' unless opts[:action] == :texts

        q = opts[:query]

        check_element_exists(q)

        comps = query(q, :numberOfComponents).first
        row_counts = []
        texts = []
        comps.times do |i|
          row_counts[i] = query(q, :numberOfRowsInComponent => i).first
          texts[i] = []
        end

        row_counts.each_with_index do |row_count, comp|
          row_count.times do |i|
            #view = query(q,[{:viewForRow => 0}, {:forComponent => 0}],:accessibilityLabel).first
            spec = [{:viewForRow => i}, {:forComponent => comp}]
            view = query(q, spec).first
            if view
              txt = query(q, spec, :accessibilityLabel).first
            else
              txt = query(q, :delegate, [{:pickerView => :view},
                                         {:titleForRow => i},
                                         {:forComponent => comp}]).first
            end
            texts[comp] << txt
          end
        end
        texts
      end

      # Set the sliders indicated by `uiquery` to `value`.
      #
      # @example
      #  slider_set_value "UISlider marked:'office slider'", 2
      #  slider_set_value "slider marked:'weather slider'", -1
      #  slider_set_value "* marked:'science slider'", 3
      #  slider_set_value "UISlider", 11
      #
      # @param [String] uiquery A query.
      # @param [Number] value The value to set the slider to.  value.to_s should
      #  produce a String representation of a Number.
      # @param [options] options Options to control the behavior of the gesture.
      # @option options [Boolean] :animate (true) Animate the change.
      # @option options [Boolean] :notify_targets (true) Simulate a UIEvent by
      #  calling every target/action pair defined on the UISliders matching
      #  `uiquery`.
      # @raise [RuntimeError] When setting the value of the sliders match by
      #  `uiquery` is not successful.
      # @return [Array<String>] An array of query results.
      def slider_set_value(uiquery, value,  options={})
        default_options =  {:animate => true,
                            :notify_targets => true}
        merged_options = default_options.merge(options)

        value_str = value.to_s

        args = [merged_options[:animate], merged_options[:notify_targets]]
        views_touched = Map.map(uiquery, :changeSlider, value_str, *args)

        msg = "Could not set value of slider to '#{value}' using query '#{uiquery}'"
        Map.assert_map_results(views_touched, msg)
        views_touched
      end

      # Calls a method on the app's AppDelegate object.
      #
      # Use this to call an arbitrary Objective-C or Swift method in your
      # app's UIApplicationDelegate.
      #
      # Commonly used to "go around" the UI speed purposes or reset the app to
      # a good known state.
      #
      # @note For methods that take arguments, don't forget to include the
      #   trailing ":"
      #
      # @param [String] selector the selector to perform on the app delegate
      # @param [Object] arguments the arguments to pass to the selector
      # @return [Object] the result of performing the selector with the argument
      def backdoor(selector, *arguments)
        parameters = {
              :selector => selector,
              :arguments => arguments
        }

        begin
          body = http({:method => :post, :path => "backdoor"}, parameters)
          result = response_body_to_hash(body)
        rescue RuntimeError => e
          raise RuntimeError, e
        end

        if result["outcome"] != "SUCCESS"
           raise RuntimeError,
%Q{backdoor call failed:
 selector => '#{selector}'
arguments => '#{arguments}'
   reason => '#{result["reason"]}'

#{result["details"]}

}
        end
        result["results"]
      end

      # Attempts to shut the app down gracefully by simulating the transition
      # to closed steps.  The server will attempt to ensure that the following
      # UIApplicationDelegate methods methods are called (in order).
      #
      # ```
      #  - (void)applicationWillResignActive:(UIApplication *)application
      #  - (void)applicationWillTerminate:(UIApplication *)application
      # ```
      #
      # @todo Shutdown the CalabashServer and close connections.
      #
      # @param [Hash] opts Options for controlling the app shutdown process.
      # @option opts [Float] :post_resign_active_delay (0.4) How long to wait
      #  after calling 'application will resign active' before calling
      #  'app will terminate'.
      # @option opts [Float] :post_will_terminate_delay (0.4) How long to wait
      #  after calling 'application will resign active' before calling 'exit'.
      # @option opts [Integer] :exit_code What code should the application
      #  exit with?  This exit code may or may not be used!  If the
      #  UIApplication responds to `terminateWithSuccess`, then that method will
      #  be called.  The exit code for `terminateWithSuccess` is undefined.
      def calabash_exit(opts={})
        default_opts = {:post_resign_active_delay => 0.4,
                        :post_will_terminate_delay => 0.4,
                        :exit_code => 0}
        merged_opts = default_opts.merge(opts)
        # Exiting the app shuts down the HTTP connection and generates ECONNREFUSED,
        # or HTTPClient::KeepAliveDisconnected
        # which needs to be suppressed.
        begin
          http({
                     :method => :post,
                     :path => 'exit',
                     :retryable_errors => Calabash::Cucumber::HTTPHelpers::RETRYABLE_ERRORS - [Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected]
               },  {
                     :post_resign_active_delay => merged_opts[:post_resign_active_delay],
                     :post_will_terminate_delay => merged_opts[:post_will_terminate_delay],
                     :exit_code => merged_opts[:exit_code]
               }
          )

        rescue Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected, SocketError
          []
        end

        if launcher.gesture_performer
          if launcher.gesture_performer.class.name == :device_agent
            delay = merged_opts[:post_resign_active_delay] +
              merged_opts[:post_will_terminate_delay] + 0.4
            sleep(delay)
            launcher.gesture_performer.send(:session_delete)
          end
        end
        true
      end

      # Get the Calabash server log level.
      # @return {String} the current log level
      def server_log_level
        _debug_level_response(http(:method => :get, :path => 'debug'))
      end

      # Set the Calabash server log level.
      # @param {String} level the log level to set (debug, info, warn, error)
      def set_server_log_level(level)
        _debug_level_response(http({:method => :post, :path => 'debug'}, {:level => level}))
      end

      # @!visibility private
      def _debug_level_response(json)
        res = JSON.parse(json)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "debug_level #{json} failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results'].first
      end

      # Starts the app and Calabash test server in the console.
      # @note It is not recommended to call this method outside of the
      #  calabash console. Call `Calabash::Cucumber::Launcher#relaunch instead.
      # @see Calabash::Cucumber::Launcher#relaunch
      # @return {Calabash::Cucumber::Launcher} the launcher object in use
      def start_test_server_in_background(args={})
        stop_test_server
        launcher = Calabash::Cucumber::Launcher.new
        launcher.relaunch(args)
        launcher
      end

      # Helper method to easily create page object instances from a cucumber execution context.
      # The advantage of using `page` to instantiate a page object class is that it
      # will automatically store a reference to the current Cucumber world
      # which is needed in the page object methods to call Cucumber-specific methods
      # like puts or embed.
      # @example Instantiating a `LoginPage` from a step definition
      #   Given(/^I am about to login to a self-hosted site$/) do
      #       @current_page = page(LoginPage).await(timeout: 30)
      #       @current_page.self_hosted_site
      #   end
      #
      # @see Calabash::IBase
      # @param {Class} clz the page object class to instantiate (passing the cucumber world and `args`)
      # @param {Array} args optional additional arguments to pass to the page object constructor
      # @return {Object} a fresh instance of `Class clz` which has been passed a reference to the cucumber World object.
      def page(clz,*args)
        clz.new(self,*args)
      end

      # Instantiates a page using `page` and calls the page's `await` method.
      # @see #page
      # @see Calabash::IBase#await
      # @example Instantiating and waiting a `LoginPage` from a step definition
      #   Given(/^I am about to login to a self-hosted site$/) do
      #       @current_page = await_page(LoginPage)
      #       @current_page.self_hosted_site
      #   end
      #
      # @see Calabash::IBase
      # @param {Class} clz the page object class to instantiate (passing the cucumber world and `args`)
      # @param {Array} args optional additional arguments to pass to the page object constructor
      # @return {Object} a fresh instance of `Class clz` which has been passed a reference to the cucumber World object.
      #   Calls await on the page object.
      def await_page(clz,*args)
        clz.new(self,*args).await
      end

      # @!visibility private
      def home_direction
        status_bar_orientation.to_sym
      end

      # Returns all accessibilityLabels of objects matching `uiquery`.
      # @param {String} uiquery query to match
      # @return {Array<String>} Returns all accessibilityLabels of objects matching `uiquery`.
      def label(uiquery)
        query(uiquery, :accessibilityLabel)
      end

      # Returns all accessibilityIdentifiers of objects matching `uiquery`.
      # @param {String} uiquery query to match
      # @return {Array<String>} Returns all accessibilityIdentifiers of objects matching `uiquery`.
      def identifier(uiquery)
        query(uiquery, :accessibilityIdentifier)
      end

      # @!visibility private
      # @deprecated use `tap_mark`
      def simple_touch(label, *args)
        tap_mark(label, *args)
      end

      # taps a view with mark `label`. Equivalent to `touch("* marked:'#{label}'")`
      # @param {String} label the mark of the view to tap
      # @param {Array} args optional additional arguments to pass to `touch`.
      # @return {Array<Hash>} array containing the serialized version of the tapped view.
      def tap_mark(label, *args)
        touch("view marked:'#{label}'", *args)
      end

      # returns the 'html' property of all objects matching the query `q`
      # @param {String} q the query to execute (should be a webView query)
      # @return {Array<String>} array containing html of all elements matching the query
      def html(q)
        query(q).map { |e| e['html'] }
      end

      # Sets the text value of the views matched by +uiquery+ to +txt+.
      #
      # You should always try to enter text "like the user would" using the
      # `keyboard_enter_text` method.  There are cases, however, when this does
      # not work or is very slow.
      #
      # Please note that if you use this method, the UITextFieldDelegate and
      # UITextViewDelegate methods ***will not be called*** if you use this
      # method of text entry.  This means that if you have UI elements that
      # respond to text changes, they ***will not be updated***.
      #
      # UIAutomation's keyboard.typeString is incredibly buggy.  Calabash goes
      # to great lengths to provide a stable typing interface.  However, there
      # are cases where our patches cause problems.  If your app crashes or
      # hangs when calling `keyboard_enter_text` there are a couple of options.
      #
      # 1. Try `fast_enter_text`.  This may or may not cause delegate methods
      #    to be called (see the note above).
      # 2. Call `keyboard.typeString` directly.  This will bypass the Calabash
      #    fixes (which sometimes cause hanging and/or crashes).
      #
      # ```
      # touch(" < touch a text field or text view > ")
      # wait_for_keyboard
      # uia("UIATarget.localTarget().frontMostApp().keyboard().typeString('your string')")
      # ```
      #
      # Please be aware that keyboard.typeString is prone to errors.  We
      # recommend using `keyboard_enter_text` or `fast_enter_text` whenever
      # possible.
      #
      # One valid use of this method is on WebViews.  Find examples in the
      # [CalWebApp features/steps/set_text_steps.rb](https://github.com/calabash/ios-webview-test-app/blob/master/CalWebViewApp/features/steps/set_text_steps.rb).
      #
      # @param [String] uiquery used to find the text input views
      # @param [String] txt the new text
      #
      # @raise[RuntimeError] If the +uiquery+ finds no matching queries or finds
      # a view that does not respond to the objc selector 'setText'
      #
      # @return [Array<String>] The text fields that were modified.
      def set_text(uiquery, txt)
        text_fields_modified = Map.map(uiquery, :setText, txt)

        msg = "query '#{uiquery}' returned no matching views that respond to 'setText'"
        Map.assert_map_results(text_fields_modified, msg)
        text_fields_modified
      end

      # Sets the text value of the views matched by +uiquery+ to <tt>''</tt>
      # (the empty string)
      #
      # Using this sparingly and with caution.  We recommend using queries and
      # touches to replicate what the _user would do_.
      #
      # @param [String] uiquery used to find the text input views
      #
      # @raise[RuntimeError] If the +uiquery+ finds no matching queries or finds
      # a view that does not respond to the objc selector 'setText'
      #
      # @return [Array<String>] The text fields that were modified.
      def clear_text(uiquery)
        views_modified = Map.map(uiquery, :setText, '')
        msg = "query '#{uiquery}' returned no matching views that respond to 'setText'"
        Map.assert_map_results(views_modified, msg)
        views_modified
      end

      # Sets user preference (NSUserDefaults) value of key `key` to `val`.
      # @example
      #   set_user_pref 'foo', {lastname: "Krukow"}
      #   # returns
      #   [
      #       {
      #       "lastname" => "Krukow"
      #       },
      #      {
      #       "firstname" => "Karl"
      #      }
      #   ]
      #
      # @param {String} key the set to set
      # @param {Object} val the (JSON_ serializable) value to set
      # @return {Object} the current user preferences
      def set_user_pref(key, val)
        res = http({:method => :post, :path => 'userprefs'},
                   {:key=> key, :value => val})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "set_user_pref #{key} = #{val} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results']
      end

      # Gets the user preference (NSUserDefaults) value for a key.
      # @param {String} key the read
      # @return {Object} the current user preferences value for `key`
      def user_pref(key)
        res = http({:method => :get, :raw => true, :path => 'userprefs'},
                   {:key=> key})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "get user_pref #{key} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results'].first
      end

      # @!visibility private
      # @todo broken currently
      def stop_test_server
        launcher = Calabash::Cucumber::Launcher.launcher_if_used
        launcher.stop if launcher
      end

      # @!visibility private
      # @todo broken currently
      def shutdown_test_server
        # Compat with Calabash Android
        stop_test_server
      end

      # Attach the current calabash launcher to a console.
      # @example
      #  You have encountered a failing cucumber Scenario.
      #  You open the console and want to start investigating the cause of the failure.
      #
      #  Use
      #
      #  > console_attach
      #
      #  to connect to the current launcher
      #
      # @param [Symbol] uia_strategy Optionally specify the uia strategy, which
      #   can be one of :shared_element, :preferences, :host.  If you don't
      #   know which to choose, don't specify one and calabash will try deduce
      #   the correct strategy to use based on the environment variables used
      #   when starting the console.
      # @return [Calabash::Cucumber::Launcher,nil] the currently active
      #  calabash launcher
      #
      # @raise [RuntimeError] This method is not available on the Xamarin Test
      #  Cloud
      def console_attach(uia_strategy = nil)
        if Calabash::Cucumber::Environment.xtc?
          raise "This method is not available on the Xamarin Test Cloud"
        end
        launcher.attach({:uia_strategy => uia_strategy})
      end

      # @!visibility private
      # TODO should be private
      def launcher
        Calabash::Cucumber::Launcher.launcher
      end

      # @!visibility private
      # TODO should be private
      def run_loop
        launcher = Calabash::Cucumber::Launcher.launcher_if_used
        if launcher
          launcher.run_loop
        else
          nil
        end
      end

      # @!visibility private
      def tail_run_loop_log
        if !run_loop
          raise "Unable to tail instruments log because there is no active run-loop"
        end

        require "calabash-cucumber/log_tailer"

        if launcher.instruments?
          Calabash::Cucumber::LogTailer.tail_in_terminal(run_loop[:log_file])
        else
          # TODO Tail the .run_loop/xcuitest/<launcher>.log?
          raise "Cannot tail a non-instruments run-loop"
        end
      end

      # @!visibility private
      def dump_run_loop_log
        if !run_loop
          raise "Unable to dump run-loop log because there is no active run-loop"
        end

        if launcher.instruments?
          cmd = %Q[cat "#{run_loop[:log_file]}" | grep -v "Default: \\*\\*\\*"]
          RunLoop.log_unix_cmd(cmd)
          puts `#{cmd}`
          true
        else
          # TODO What should we dump in non-instruments runs?
          raise "Cannot dump non-instruments run-loop"
        end
      end

      # @!visibility private
      def query_action_with_options(action, uiquery, options)
        uiquery, options = extract_query_and_options(uiquery, options)
        views_touched = launcher.gesture_performer.send(action, options)
        unless uiquery.nil?
          msg = "#{action} could not find view: '#{uiquery}', args: #{options}"
          Map.assert_map_results(views_touched, msg)
        end
        views_touched
      end

      # @!visibility private
      def extract_query_and_options(uiquery, options)
        options = prepare_query_options(uiquery, options)
        return options[:query], options
      end

      # @!visibility private
      def assert_home_direction(expected)
        unless expected.to_sym == home_direction
          screenshot_and_raise "Expected home button to have direction #{expected} but had #{home_direction}"
        end
      end

      # @!visibility private
      def prepare_query_options(uiquery, options)
        opts = options.dup
        if uiquery.is_a?(Array)
          raise 'No elements in array' if uiquery.empty?
          uiquery = uiquery.first
        end #this is deliberately not elsif (uiquery.first could be a hash)

        if uiquery.is_a?(Hash)
          opts[:offset] = point_from(uiquery, options)
          uiquery = nil
        end
        opts[:query] = uiquery
        opts
      end

    end
  end
end


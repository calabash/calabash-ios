module Calabash
  module Cucumber

    # An interface to the DeviceAgent Query and Gesture API.
    #
    # Unlike Calabash or UIA gestures, all DeviceAgent gestures wait for the
    # uiquery to match a view.  This behavior match the Calabash 2.0 and
    # Calabash 0.x Android behavior.
    #
    # This API is work in progress.  There are several methods that are
    # experimental and several methods that will probably removed soon.
    #
    # Wherever possible use Core#query and the gestures defined in Core.
    #
    # TODO Screenshots
    class DeviceAgent < BasicObject

      # @!visibility private
      #
      # @param [RunLoop::DeviceAgent::Client] client The DeviceAgent client.
      # @param [Cucumber::World] world The Cucumber World.
      def initialize(client, world)
        @client = client
        @world = world
      end

      # @!visibility private
      def to_s
        if client.running?
          version = client.server_version["bundle_short_version"]
        else
          version = "not connected!"
        end
        "#<DeviceAgent API: #{version}>"
      end

      # @!visibility private
      def inspect
        to_s
      end

      # @!visibility private
      # https://github.com/awesome-print/awesome_print/pull/253
      # Awesome print patch for BasicObject
      def ai(_)
        to_s
      end

      # Query the UI for elements.
      #
      # @example
      #  query({id: "login", :type "Button"})
      #
      #  query({marked: "login"})
      #
      #  query({marked: "login", type: "TextField"})
      #
      #  query({type: "Button", index: 2})
      #
      #  query({text: "Log in"})
      #
      #  query({id: "hidden button", :all => true})
      #
      #  # Escaping single quote is not necessary, but supported.
      #  query({text: "Karl's problem"})
      #  query({text: "Karl\'s problem"})
      #
      #  # Escaping double quote is not necessary, but supported.
      #  query({text: "\"To know is not enough.\""})
      #  query({text: %Q["To know is not enough."]})
      #
      # Querying for text with newlines is not supported yet.
      #
      # The query language supports the following keys:
      # * :marked - accessibilityIdentifier, accessibilityLabel, text, and value
      # * :id - accessibilityIdentifier
      # * :type - an XCUIElementType shorthand, e.g. XCUIElementTypeButton =>
      #   Button. See the link below for available types.  Note, however that
      #   some XCUIElementTypes are not available on iOS.
      # * :index - Applied after all other specifiers.
      # * :all - Filter the result by visibility. Defaults to false. See the
      #   discussion below about visibility.
      #
      # ### Visibility
      #
      # The rules for visibility are:
      #
      # 1. If any part of the view is visible, the visible.
      # 2. If the view has alpha 0, it is not visible.
      # 3. If the view has a size (0,0) it is not visible.
      # 4. If the view is not within the bounds of the screen, it is not visible.
      #
      # Visibility is determined using the "hitable" XCUIElement property.
      # XCUITest, particularly under Xcode 7, is not consistent about setting
      # the "hitable" property correctly.  Views that are not "hitable" will
      # still respond to gestures. For this reason, gestures use the
      # element["rect"] for computing the touch point.
      #
      # Regarding rule #1 - this is different from the Calabash iOS and Android
      # definition of visibility which requires the mid-point of the view to be
      # visible.
      #
      # Please report visibility problems.
      #
      # ### Results
      #
      # Results are returned as an Array of Hashes.  The key/value pairs are
      # similar to those returned by the Calabash iOS Server, but not exactly
      # the same.
      #
      # ```
      # [
      #  {
      #    "enabled": true,
      #    "id": "mostly hidden button",
      #    "hitable": true,
      #    "rect": {
      #      "y": 459,
      #      "x": 24,
      #      "height": 25,
      #      "width": 100
      #    },
      #    "label": "Mostly Hidden",
      #    "type": "Button",
      #    "hit_point": {
      #      "x": 25,
      #      "y": 460
      #    },
      #  }
      # ]
      # ```
      #
      # @see http://masilotti.com/xctest-documentation/Constants/XCUIElementType.html
      # @param [Hash] uiquery A hash describing the query.
      # @return [Array<Hash>] An array of elements matching the `uiquery`.
      def query(uiquery)
        client.query(uiquery)
      end

      # Perform a clear text on the active view
      def clear_text
        client.clear_text
      end

      # Query for the center of a view.
      #
      # @see #query
      #
      # This method waits for the query to match at least one element.
      #
      # @param uiquery See #query
      # @return [Hash] The center of first view matched by query.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      def query_for_coordinate(uiquery)
        with_screenshot_on_failure { client.query_for_coordinate(uiquery) }
      end

      # Perform a touch on the center of the first view matched the uiquery.
      #
      # This method waits for the query to match at least one element.
      #
      # @see #query
      #
      # @param [Hash] uiquery See #query for examples.
      # @return [Array<Hash>] The view that was touched.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      def touch(uiquery)
        with_screenshot_on_failure { client.touch(uiquery) }
      end

      # Perform a touch at a coordinate.
      #
      # This method does not wait; the touch is performed immediately.
      #
      # @param [Hash] coordinate The coordinate to touch.
      def touch_coordinate(coordinate)
        client.touch_coordinate(coordinate)
      end

      # Perform a touch at a point.
      #
      # This method does not wait; the touch is performed immediately.
      #
      # @param [Hash] x the x coordinate
      # @param [Hash] y the y coordinate
      def touch_point(x, y)
        client.touch_point(x, y)
      end

      # Perform a double tap on the center of the first view matched the uiquery.
      #
      # @see #query
      #
      # This method waits for the query to match at least one element.
      #
      # @param uiquery See #query
      # @return [Array<Hash>] The view that was touched.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      def double_tap(uiquery)
        with_screenshot_on_failure { client.double_tap(uiquery) }
      end

      # Perform a two finger tap on the center of the first view matched the uiquery.
      #
      # @see #query
      #
      # This method waits for the query to match at least one element.
      #
      # @param uiquery See #query
      # @return [Array<Hash>] The view that was touched.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      def two_finger_tap(uiquery)
        with_screenshot_on_failure { client.two_finger_tap(uiquery) }
      end

      # Perform a long press on the center of the first view matched the uiquery.
      #
      # @see #query
      #
      # This method waits for the query to match at least one element.
      #
      # @param uiquery See #query
      # @param [Numeric] duration How long to press.
      # @return [Array<Hash>] The view that was touched.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      def long_press(uiquery, duration)
        with_screenshot_on_failure { client.long_press(uiquery, {:duration => duration}) }
      end

      # Returns true if there is a keyboard visible.
      #
      # Scheduled for removal in 0.21.0.  Use Core#keyboard_visible?. If you
      # find an example where Core#keyboard_visible? does not find visible
      # keyboard, please report it.
      #
      # @deprecated 0.21.0 Use Core#keyboard_visible?
      def keyboard_visible?
        client.keyboard_visible?
      end

      # Enter text into the UITextInput view that is the first responder.
      #
      # The first responder is the view that is attached to the keyboard.
      #
      # Scheduled for removal in 0.21.0. Use Core#enter_text. If you find an
      # example where Core#enter_text does not work, please report it.
      #
      # @param [String] text the text to enter
      #
      # @raise [RuntimeError] if there is no visible keyboard.
      # @deprecated 0.21.0 Use Core#enter_text
      def enter_text(text)
        with_screenshot_on_failure { client.enter_text(text) }
      end

      # Enter text into the first view matched by uiquery.
      #
      # This method waits for the query to match at least one element and for
      # the keyboard to appear.
      #
      # Scheduled for removal in 0.21.0. Use Core#enter_text_in. If you find an
      # example where Core#enter_text_in does not work, please report it.
      #
      # @raise [RuntimeError] if no view matches the uiquery after waiting.
      # @raise [RuntimeError] if the touch does not cause a keyboard to appear.
      #
      # @deprecated 0.21.0 Use Core#enter_text
      def enter_text_in(uiquery, text)
        with_screenshot_on_failure do
          client.touch(uiquery)
          client.wait_for_keyboard
          client.enter_text(text)
        end
      end

      # EXPERIMENTAL: This API may change.
      #
      # Is an alert generated by your Application visible?
      #
      # This does not detect SpringBoard alerts.
      #
      # @see #springboard_alert
      #
      # @see #springboard_alert
      def app_alert_visible?
        client.alert_visible?
      end

      # EXPERIMENTAL: This API may change.
      #
      # Queries for an alert generate by your Application.
      #
      # This does not detect SpringBoard alerts.
      #
      # @see #spring_board_alert
      #
      # @return [Array<Hash>] The view that was touched.
      def app_alert
        client.alert
      end

      # EXPERIMENTAL: This API may change.
      #
      # Is an alert generated by SpringBoard visible?
      #
      # This does not detect alerts generated by your Application.
      #
      # Examples of SpringBoard alerts are:
      # * Privacy Alerts generated by requests for access to protected iOS
      #   services like Contacts and Location,
      # * "No SIM card"
      # * iOS Update available
      #
      # @see #alert
      def springboard_alert_visible?
        client.springboard_alert_visible?
      end

      # EXPERIMENTAL: This API may change.
      #
      # Queries for an alert generated by SpringBoard.
      #
      # This does not detect alerts generated by your Application.
      #
      # Examples of SpringBoard alerts are:
      # * Privacy Alerts generated by requests for access to protected iOS
      #   services like Contacts and Location,
      # * "No SIM card"
      # * iOS Update available
      #
      # @see #alert
      def springboard_alert
        client.springboard_alert
      end

      # EXPERIMENTAL: This API may change.
      #
      # Disables Calabash's ability to dismiss SpringBoard alerts automatically.
      def dismiss_springboard_alerts_automatically!
        client.set_dismiss_springboard_alerts_automatically(true)
      end

      # EXPERIMENTAL: This API may change.
      #
      # Enables Calabash's ability to dismiss SpringBoard alerts automatically.
      def dismiss_springboard_alerts_manually!
        client.set_dismiss_springboard_alerts_automatically(false)
      end

      # EXPERIMENTAL: This API may change.
      #
      # Enables or disables Calabash's ability to dismiss SpringBoard alerts
      # automatically.
      #
      # @param true_or_false
      def set_dismiss_springboard_alerts_automatically(true_or_false)
        client.set_dismiss_springboard_alerts_automatically(true_or_false)
      end

      # EXPERIMENTAL: This API may change.
      #
      # Wait for a SpringBoard alert to appear.
      def wait_for_springboard_alert(timeout=nil)
        if timeout
          client.wait_for_springboard_alert(timeout)
        else
          client.wait_for_springboard_alert
        end
      end

      # EXPERIMENTAL: This API may change.
      #
      # Wait for a SpringBoard alert to disappear.
      def wait_for_no_springboard_alert(timeout=nil)
        if timeout
          client.wait_for_no_springboard_alert(timeout)
        else
          client.wait_for_no_springboard_alert
        end
      end

      # EXPERIMENTAL: This API may change.
      #
      # @param [String] button_title The title of the button to touch.
      #
      # Please pay attention to non-ASCII characters in button titles.
      #
      # "Don’t Allow" => UTF-8 single quote in Don't
      # "Don't Allow" => ASCII single quote in Don't
      #
      # Only UTF-8 string will match the button title.
      #
      # @return true if a SpringBoard alert is dismissed.
      #
      # @raise RuntimeError If there is no SpringBoard alert visible
      # @raise RuntimeError If the SpringBoard alert does not have a button
      #   matching button_title.
      # @raise RuntimeError If there is an error dismissing the SpringBoard
      #   alert.
      def dismiss_springboard_alert(button_title)
         client.dismiss_springboard_alert(button_title)
      end

=begin
PRIVATE
=end
      private

      # @!visibility private
      attr_reader :client, :world

      # @!visibility private
      def with_screenshot_on_failure(&block)
        begin
          block.call
        rescue => e
          world.send(:fail, e.message)
        end
      end
    end
  end
end

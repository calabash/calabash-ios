require 'httpclient'
require 'json'
require 'geocoder'
require 'calabash-cucumber/uia'
require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/connection'
require 'calabash-cucumber/connection_helpers'
require 'calabash-cucumber/launch/simulator_launcher'
require 'calabash-cucumber/query_helpers'
require 'calabash-cucumber/playback_helpers'
require 'calabash-cucumber/failure_helpers'
require 'calabash-cucumber/status_bar_helpers'
require 'calabash-cucumber/rotation_helpers'
require 'calabash-cucumber/map'
require 'calabash-cucumber/utils/logging'


# legacy support - module was deprecated 0.9.169
# replaced with simulator-launcher
require 'calabash-cucumber/launch/simulator_helper'

module Calabash
  module Cucumber
    module Core

      include Calabash::Cucumber::Logging
      include Calabash::Cucumber::EnvironmentHelpers
      include Calabash::Cucumber::ConnectionHelpers
      include Calabash::Cucumber::QueryHelpers
      include Calabash::Cucumber::FailureHelpers
      include Calabash::Cucumber::Map
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::StatusBarHelpers
      include Calabash::Cucumber::RotationHelpers
      include Calabash::Cucumber::PlaybackHelpers

      # @!visibility private
      # @deprecated Use Cucumber's step method (avoid this: using step is not considered best practice).
      # Used in older cucumber versions that didn't have the `step` method.
      # Shouldn't be used anymore.
      def macro(txt)
        if self.respond_to? :step
          step(txt)
        else
          Then txt
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
        map(uiquery, :query, *args)
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
      # @return [Array] an array of that contains the result of calling the
      #   objc selector `description` on each matching view.
      #
      def flash(uiquery, *args)
        # todo deprecate the *args argument in the flash method
        # todo :flash operation should return views as JSON objects
        map(uiquery, :flash, *args).compact
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

      # Queries all views in view hierarchy, even if not visible.
      # @deprecated use the 'all' or 'visible' modifier in query syntax
      # {}
      def query_all(uiquery, *args)
        msg0 = "use the 'all' or 'visible' query language feature"
        msg1 = 'see: https://github.com/calabash/calabash-ios/wiki/05-Query-syntax'
        msg = "#{msg0}\n#{msg1}"
        _deprecated('0.9.133', msg, :warn)
        map("all #{uiquery}", :query, *args)
      end

      # Performs the `tap` gesture on the (first) view that matches
      # query `uiquery`. Note that `touch` assumes the view is visible and not animating.
      # If the view is not visible `touch` will fail. If the view is animating
      # `touch` will *silently* fail.
      # By default, taps the center of the view.
      # @see #wait_tap
      # @see Calabash::Cucumber::Operations#tap_mark
      # @see #tap_point
      # @param {String} uiquery query describing view to tap. Note `nil` is allowed and is interpreted as
      #   `tap_point(options[:offset][:x],options[:offset][:y])`
      # @param {Hash} options option for modifying the details of the touch
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @return {Array<Hash>} array containing the serialized version of the tapped view.
      def touch(uiquery, options={})
        query_action_with_options(:touch, uiquery, options)
      end

      # Performs the `tap` gesture on an absolute coordinate.
      # @see #wait_tap
      # @see Calabash::Cucumber::Operations#tap_mark
      # @see #touch
      # @param {Numeric} x x-coordinate to tap
      # @param {Numeric} y y-coordinate to tap
      # @return {Boolean} `true`
      def tap_point(x,y)
        touch(nil, offset: {x:x, y:y})
      end

      # Performs the `tap` gesture on the (first) view that matches
      # query `uiquery`. As opposed to `touch`, `wait_tap` is a high-level method that combines:
      # (1) waiting for the view to appear,
      # (2) waiting for animations to complete on the view (and it's parents) and (3) actually tapping the view.
      # This removes the common boiler-plate trio: `wait_for_element_exists`, `wait_for_none_animating`, `touch`.
      #
      # By default, taps the center of the view.
      # @see #touch
      # @see #tap_point
      # @param {String} uiquery query describing view to tap. Note `nil` is not allowed.
      # @param {Hash} options option for modifying the details of the touch
      # @option options {Hash} :offset (nil) optional offset to tap point. Offset has an `:x` and `:y` key
      #   the tap will be performed on the center of the view plus the offset.
      # @option options {Hash} :timeout (30) maximum number of seconds to wait for the view to appear
      # @option options {Hash} :frequency (0.2) polling frequency to for checking if the view is present (>= 0.1)
      # @return {Array<Hash>} serialized version of the tapped view
      def wait_tap(uiquery, options={})
        _uiquery, options = extract_query_and_options(uiquery, options)
        launcher.actions.wait_tap(options)
      end

      # Performs the "double tap" gesture on the (first) view that matches
      # query `uiquery`. Note that this assumes the view is visible and not animating.
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
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
      # query `uiquery`. Note that this assumes the view is visible and not animating.
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      # By default, taps the center of the view.
      # @example
      #   two_finger_tap "view marked:'Third'", offset:{x:100}
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @return {Array<Hash>} array containing the serialized version of the tapped view.
      def two_finger_tap(uiquery,options={})
        query_action_with_options(:two_finger_tap, uiquery, options)
      end

      # Performs the "flick" gesture on the (first) view that matches
      # query `uiquery`. Note that this assumes the view is visible and not animating.
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      # By default, the gesture starts at the center of the view and "flicks" according to `delta`.
      # A flick is similar to a swipe.
      # @example
      #   flick("MKMapView", {x:100,y:50})
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} delta coordinate describing the direction to flick
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option delta {Numeric} :x (0) optional. The force and direction of the flick on the `x`-axis
      # @option delta {Numeric} :y (0) optional. The force and direction of the flick on the `y`-axis
      # @return {Array<Hash>} array containing the serialized version of the touched view.
      def flick(uiquery, delta, options={})
        uiquery, options = extract_query_and_options(uiquery, options)
        options[:delta] = delta
        views_touched = launcher.actions.flick(options)
        unless uiquery.nil?
          screenshot_and_raise "flick could not find view: '#{uiquery}', args: #{options}" if views_touched.empty?
        end
        views_touched
      end

      # Performs the "long press" or "touch and hold" gesture on the (first) view that matches
      # query `uiquery`. Note that this assumes the view is visible and not animating.
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      # By default, the gesture starts at the center of the view.
      # @example
      #   touch_hold "webView css:'input'", duration:10, offset:{x: -40}
      # @param {String} uiquery query describing view to touch.
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option options {Numeric} :duration (3) duration of the 'hold'.
      # @return {Array<Hash>} array containing the serialized version of the touched view.
      def touch_hold(uiquery, options={})
        query_action_with_options(:touch_hold, uiquery, options)
      end

      # Performs a "swipe" gesture.
      # By default, the gesture starts at the center of the screen.
      # @todo `swipe` is an old style API which doesn't take a query as its first argument. We should migrate this.
      # @note Due to a bug in Apple's UIAutomation, swipe is broken on certain views in the iOS Simulator. It works fully on devices.
      #   {https://github.com/calabash/calabash-ios/issues/253}
      # @example
      #   swipe :left
      # @example
      #   swipe :down, offset:{x:10,y:50}, query:"MKMapView"
      # @param {String} dir the direction to swipe (symbols can also be used).
      # @param {Hash} options option for modifying the details of the touch.
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option options {String} :query (nil) if specified, the swipe will be made relative to this query.
      # @return {Array<Hash>,String} array containing the serialized version of the touched view if `options[:query]` is given.
      def swipe(dir, options={})
        unless uia_available?
          options = options.merge(:status_bar_orientation => status_bar_orientation)
        end
        launcher.actions.swipe(dir.to_sym, options)
      end


      # Performs the "pan" or "drag-n-drop" gesture on from the `from` parameter to the `to` parameter (both are queries).
      # @example
      #   q1="* marked:'Cell 3' parent tableViewCell descendant tableViewCellReorderControl"
      #   q2="* marked:'Cell 6' parent tableViewCell descendant tableViewCellReorderControl"
      #   pan q1, q2, duration:4
      # @param {String} from query describing view to start the gesture
      # @param {String} to query describing view to end the gesture
      # @option options {Hash} :offset (nil) optional offset to touch point. Offset supports an `:x` and `:y` key
      #   and causes the touch to be offset with `(x,y)` relative to the center (`center + (offset[:x], offset[:y])`).
      # @option options {Numeric} :duration (1) duration of the 'pan'.
      # @return {Array<Hash>} array containing the serialized version of the touched view.
      def pan(from, to, options={})
        launcher.actions.pan(from, to, options)
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
        launcher.actions.pinch(in_out.to_sym,options)
      end

      # @!visibility private
      # @deprecated
      def cell_swipe(options={})
        if uia_available?
          raise 'cell_swipe not supported with instruments, simply use swipe with a query that matches the cell'
        end
        playback('cell_swipe', options)
      end

      # Scroll a scroll view in a direction. By default scrolls half the frame size.
      # @example
      #   scroll("UITableView", :down)
      # @note this is implemented by calling the Obj-C `setContentOffset:animated:` method and can do things users cant.
      #
      # @param {String} uiquery query describing view scroll (should be  UIScrollView or a web view).
      def scroll(uiquery, direction)
        views_touched=map(uiquery, :scroll, direction)
        msg = "could not find view to scroll: '#{uiquery}', args: #{direction}"
        assert_map_results(views_touched, msg)
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
        views_touched=map(uiquery, :scrollToRow, number)
        msg = "unable to scroll: '#{uiquery}' to: #{number}"
        assert_map_results(views_touched, msg)
        views_touched
      end

      # Scroll a table view to a section and row. Table view can have multiple sections.
      #
      # @todo should expose a non-option first argument query and required parameters `section`, `row`
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
      #
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
        views_touched=map(uiquery, :scrollToRow, row.to_i, sec.to_i, *args)
        msg = "unable to scroll: '#{uiquery}' to '#{options}'"
        assert_map_results(views_touched, msg)
        views_touched
      end

      # scrolls to mark in a UITableView
      #
      # calls the :scrollToRowWithMark server route
      #
      #    scroll_to_row_with_mark(mark, {:scroll_position => :top}) #=> scroll to the top of the item with the given mark
      # scroll_to_row_with_mark(mark, {:scroll_position => :bottom}) #=> scroll to the bottom of the item with the given mark
      #
      # allowed options
      #     :query => a query string
      #         default => 'tableView'
      #         example => "tableView marked:'hit songs'"
      #
      #     :scroll_position => the position to scroll to
      #         default => :middle
      #         allowed => {:top | :middle | :bottom}
      #
      #     :animate => animate the scrolling
      #         default => true
      #         allowed => {true | false}
      #
      # raises an exception if the scroll cannot be performed.
      # * the mark is nil
      # * the :query finds no table view
      # * table view does not contain a cell with the given mark
      # * :scroll_position is invalid
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

        views_touched=map(uiquery, :scrollToRowWithMark, mark, *args)
        msg = options[:failed_message] || "Unable to scroll: '#{uiquery}' to: #{options}"
        assert_map_results(views_touched, msg)
        views_touched
      end

      # scrolls to item in section in a UICollectionView
      #
      # calls the :collectionViewScroll server route
      #
      # item and section are zero-indexed
      #
      #    scroll_to_collection_view_item(0, 2, {:scroll_position => :top}) #=> scroll to item 0 in section 2 to top
      # scroll_to_collection_view_item(5, 0, {:scroll_position => :bottom}) #=> scroll to item 5 in section 0 to bottom
      #
      # allowed options
      #     :query => a query string
      #         default => 'collectionView'
      #         example => "collectionView marked:'hit songs'"
      #
      #     :scroll_position => the position to scroll to
      #         default => :top
      #         allowed => {:top | :center_vertical | :bottom | :left | :center_horizontal | :right}
      #
      #     :animate => animate the scrolling
      #         default => true
      #         allowed => {true | false}
      #
      #     :failed_message => the message to display on failure
      #         default => nil - will display a default failure message
      #         allowed => any string
      #
      # raises an exception if the scroll cannot be performed.
      # * the :query finds no collection view
      # * collection view does not contain a cell at item/section
      # * :scroll_position is invalid
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

        views_touched=map(uiquery, :collectionViewScroll, item.to_i, section.to_i, scroll_position, animate)

        if opts[:failed_message]
          msg = opts[:failed_message]
        else
          msg = "unable to scroll: '#{uiquery}' to item '#{item}' in section '#{section}'"
        end

        assert_map_results(views_touched, msg)
        views_touched
      end

      # scrolls to mark in a UICollectionView
      #
      # calls the :collectionViewScrollToItemWithMark server route
      #
      #    scroll_to_collection_view_item_with_mark(mark, {:scroll_position => :top}) #=> scroll to the top of the item with the given mark
      # scroll_to_collection_view_item_with_mark(mark, {:scroll_position => :bottom}) #=> scroll to the bottom of the item with the given mark
      #
      # allowed options
      #     :query => a query string
      #         default => 'collectionView'
      #         example => "collectionView marked:'hit songs'"
      #
      #     :scroll_position => the position to scroll to
      #         default => :top
      #         allowed => {:top | :center_vertical | :bottom | :left | :center_horizontal | :right}
      #
      #     :animate => animate the scrolling
      #         default => true
      #         allowed => {true | false}
      #
      #     :failed_message => the message to display on failure
      #         default => nil - will display a default failure message
      #         allowed => any string
      #
      # raises an exception if the scroll cannot be performed.
      # * the mark is nil
      # * the :query finds no collection view
      # * collection view does not contain a cell with the given mark
      # * :scroll_position is invalid
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

        views_touched=map(uiquery, :collectionViewScrollToItemWithMark, mark, *args)
        msg = opts[:failed_message] || "Unable to scroll: '#{uiquery}' to cell with mark: '#{mark}' with #{opts}"
        assert_map_results(views_touched, msg)
        views_touched
      end

      # @param {Fixnum} secs number of seconds to be in the background (should not be more than 60 secs)
      # Sends app to background. Simulates pressing the home button.
      def send_app_to_background(secs)
        launcher.actions.send_app_to_background(secs)
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
      def move_wheel(opts={})
        q = opts[:query] || 'pickerView'
        wheel = opts[:wheel] || 0
        dir = opts[:dir] || :down

        raise 'Wheel index must be non negative' if wheel < 0
        raise "Only up and down supported :dir (#{dir})" unless [:up, :down].include?(dir)

        if ENV['OS'] == 'ios4'
          playback "wheel_#{dir}", :query => "#{q} pickerTable index:#{wheel}"
        elsif ios7?
          raise NotImplementedError
        else
          playback "wheel_#{dir}", :query => "#{q} pickerTableView index:#{wheel}"
        end

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

      # Calls a method on the app's AppDelegate object.
      # This is an escape hatch for calling an arbitraty hook inside (the test build) of your app.
      # Typically used to "go around" the UI for speed purposes.
      # You must create a method on you app delegate of the form:
      #
      #     - (NSString *) calabashBackdoor:(NSString *)aIgnorable;
      #
      # or if you want to pass parameters
      #
      #     - (NSString *) calabashBackdoor:(NSDictionary *)params;
      # @example
      #   backdoor("calabashBackdoor:", '')
      # @example
      #   backdoor("calabashBackdoor:", {example:'param'})
      # @param {String} sel the selector to perform on the app delegate
      # @param {Object} arg the argument to pass to the selector
      # @return {Object} the result of performing the selector with the argument (serialized)
      def backdoor(sel, arg)
        json = {
              :selector => sel,
              :arg => arg
        }
        res = http({:method => :post, :path => 'backdoor'}, json)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "backdoor #{json} failed because: #{res['reason']}\n#{res['details']}"
        end
        res['result']
      end

      # Kills the app.
      def calabash_exit
        # Exiting the app shuts down the HTTP connection and generates ECONNREFUSED,
        # or HTTPClient::KeepAliveDisconnected
        # which needs to be suppressed.
        begin
          http({:method => :post, :path => 'exit', :retryable_errors => Calabash::Cucumber::HTTPHelpers::RETRYABLE_ERRORS - [Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected]})
        rescue Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected
          []
        end
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
      # @see Calabash::Cucumber::Launcher#relaunch
      # @return {Calabash::Cucumber::Launcher} the launcher object in use
      def start_test_server_in_background(args={})
        stop_test_server
        @calabash_launcher = Calabash::Cucumber::Launcher.new()
        @calabash_launcher.relaunch(args)
        @calabash_launcher
      end

      # @!visibility private
      # @todo broken currently
      def stop_test_server
        l = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        l.stop if l
      end

      # @!visibility private
      # @todo broken currently
      def shutdown_test_server
        # Compat with Calabash Android
        stop_test_server
      end

      # @!visibility private
      def console_attach
        # setting the @calabash_launcher here for backward compatibility
        @calabash_launcher = launcher.attach
      end

      # @!visibility private
      def launcher
        # setting the @calabash_launcher here for backward compatibility
        @calabash_launcher = Calabash::Cucumber::Launcher.launcher
      end

      # @!visibility private
      def query_action_with_options(action, uiquery, options)
        uiquery, options = extract_query_and_options(uiquery, options)
        views_touched = launcher.actions.send(action, options)
        unless uiquery.nil?
          msg = "#{action} could not find view: '#{uiquery}', args: #{options}"
          assert_map_results(views_touched, msg)
        end
        views_touched
      end

      # @!visibility private
      def extract_query_and_options(uiquery, options)
        options = prepare_query_options(uiquery, options)
        return options[:query], options
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


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

      # Performs the `tap` gesture on the (first) view that matches query `uiquery`.
      #
      # As opposed to `touch`, `wait_tap` is a high-level method that combines:
      #
      # 1. waiting for the view to appear,
      # 2. waiting for animations to complete on the view (and it's parents) and
      # 3. actually tapping the view.
      #
      # This removes the common boiler-plate trio: `wait_for_element_exists`,
      # `wait_for_none_animating`, `touch`.
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
        # noinspection RubyUnusedLocalVariable
        _uiquery, options = extract_query_and_options(uiquery, options)
        launcher.actions.wait_tap(options)
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
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      #
      # By default, taps the center of the view.
      #
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
      # query `uiquery`.
      #
      # @note This assumes the view is visible and not animating.
      #
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      #
      # By default, the gesture starts at the center of the view and "flicks" according to `delta`.
      #
      # A flick is similar to a swipe.
      #
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
      # query `uiquery`.
      #
      # @note This assumes the view is visible and not animating.
      #
      # If the view is not visible it will fail with an error. If the view is animating
      # it will *silently* fail.
      #
      # By default, the gesture starts at the center of the view.
      #
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
      #
      # @todo `swipe` is an old style API which doesn't take a query as its
      #  first argument. We should migrate this.
      #
      # @note Due to a bug in Apple's UIAutomation, swipe is broken on certain
      #  views in the iOS Simulator. Swiping works on devices.
      #  {https://github.com/calabash/calabash-ios/issues/253}
      #
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


      # Performs the "pan" or "drag-n-drop" gesture on from the `from` parameter
      # to the `to` parameter (both are queries).
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
        views_touched=map(uiquery, :scrollToRow, row.to_i, sec.to_i, *args)
        msg = "unable to scroll: '#{uiquery}' to '#{options}'"
        assert_map_results(views_touched, msg)
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

        views_touched=map(uiquery, :scrollToRowWithMark, mark, *args)
        msg = options[:failed_message] || "Unable to scroll: '#{uiquery}' to: #{options}"
        assert_map_results(views_touched, msg)
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
      # @raise [RuntimeException] if the scroll cannot be performed
      # @raise [RuntimeException] :query finds no collection view
      # @raise [RuntimeException] the collection view does not contain a cell at item/section
      # @raise [RuntimeException] :scroll_position is invalid
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
      # @raise [RuntimeException] if the scroll cannot be performed
      # @raise [RuntimeException] if the mark is nil
      # @raise [RuntimeException] :query finds no collection view
      # @raise [RuntimeException] the collection view does not contain a cell
      #  with the mark
      # @raise [RuntimeException] :scroll_position is invalid
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

      # Sends app to background. Simulates pressing the home button.
      # @param {Fixnum} secs number of seconds to be in the background
      #  `should not be more than 60 secs`
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
      #
      # This is an escape hatch for calling an arbitrary hook inside
      # (the test build) of your app.  Commonly used to "go around" the UI for
      # speed purposes or reset the app to a good known state.
      #
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
      # @note It is not recommended to call this method outside of the
      #  calabash console. Call `Calabash::Cucumber::Launcher#relaunch instead.
      # @see Calabash::Cucumber::Launcher#relaunch
      # @return {Calabash::Cucumber::Launcher} the launcher object in use
      def start_test_server_in_background(args={})
        stop_test_server
        @calabash_launcher = Calabash::Cucumber::Launcher.new()
        @calabash_launcher.relaunch(args)
        @calabash_launcher
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

      # taps a view with mark `hash_or_string`
      # @deprecated In later Calabash versions we will change the semantics of `tap` to take a general query
      #   (instead of a 'mark' now). We're deprecating this now to prepare people for a breaking change.
      # @param {String} hash_or_string mark to pass to call `tap_mark(hash_or_string)`.
      # @return {Array<Hash>} array containing the serialized version of the tapped view.
      def tap(hash_or_string, *args)
        deprecation_msg = 'Use tap_mark instead. In later Calabash versions we will change the semantics of `tap` to take a general query.'
        _deprecated('0.10.0', deprecation_msg, :warn)
        if hash_or_string.is_a?(String)
          tap_mark(hash_or_string, *args)
        elsif hash_or_string.respond_to?(:[])
          wait_tap(hash_or_string[:query], hash_or_string)
        else
          raise(ArgumentError, "first parameter to tap must be a string or a hash. Was: #{hash_or_string.class}, #{hash_or_string}")
        end
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

      # sets the text value of the views matched by +uiquery+ to +txt+
      #
      # @deprecated since 0.9.145
      #
      # we have stopped testing this method.  you have been warned.
      #
      # * to enter text using the native keyboard use 'keyboard_enter_text'
      # * to delete text use 'keyboard_enter_text('Delete')"
      # * to clear a text field or text view:
      #   - RECOMMENDED: use queries and touches to replicate what the user would do
      #     - for text fields, implement a clear text button and touch it
      #     - for text views, use touches to reveal text editing popup
      #       see https://github.com/calabash/calabash-ios/issues/151
      #   - use 'clear_text'
      #  https://github.com/calabash/calabash-ios/wiki/03.5-Calabash-iOS-Ruby-API
      #
      # raises an error if the +uiquery+ finds no matching queries or finds
      # a view that does not respond to the objc selector 'setText'
      def set_text(uiquery, txt)
        msgs = ["'set_text' is deprecated and its behavior is now unpredictable",
                "* to enter text using the native keyboard use 'keyboard_enter_text'",
                "* to delete text use 'keyboard_enter_text('Delete')",
                '* to clear a text field or text view:',
                '  - RECOMMENDED: use queries and touches to replicate what the user would do',
                '    * for text fields, implement a clear text button and touch it',
                '    * for text views, use touches to reveal text editing popup',
                '    see https://github.com/calabash/calabash-ios/issues/151',
                "  - use 'clear_text'",
                'https://github.com/calabash/calabash-ios/wiki/03.5-Calabash-iOS-Ruby-API']
        msg = msgs.join("\n")
        _deprecated('0.9.145', msg, :warn)

        text_fields_modified = map(uiquery, :setText, txt)

        msg = "query '#{uiquery}' returned no matching views that respond to 'setText'"
        assert_map_results(text_fields_modified, msg)
        text_fields_modified
      end

      # sets the text value of the views matched by +uiquery+ to <tt>''</tt>
      # (the empty string)
      #
      # using this sparingly and with caution
      #
      #
      # it is recommended that you instead do some combination of the following
      #
      # * use queries and touches to replicate with the user would
      #   - for text fields, implement a clear text button and touch it
      #   - for text views, use touches to reveal text editing popup
      #   see https://github.com/calabash/calabash-ios/issues/151
      #
      #  https://github.com/calabash/calabash-ios/wiki/03.5-Calabash-iOS-Ruby-API
      #
      # raises an error if the +uiquery+ finds no matching queries or finds
      # a _single_ view that does not respond to the objc selector 'setText'
      #
      # IMPORTANT
      # calling:
      #
      #     > clear_text("view")
      #
      # will clear the text on _all_ visible views that respond to 'setText'
      def clear_text(uiquery)
        views_modified = map(uiquery, :setText, '')
        msg = "query '#{uiquery}' returned no matching views that respond to 'setText'"
        assert_map_results(views_modified, msg)
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
        l = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        l.stop if l
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
      # @return [Calabash::Cucumber::Launcher,nil] the currently active
      #  calabash launcher
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


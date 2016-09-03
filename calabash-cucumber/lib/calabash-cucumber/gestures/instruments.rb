module Calabash
  module Cucumber
    # @!visibility private
    module Gestures

      require "calabash-cucumber/gestures/performer"

      # @!visibility private
      class Instruments < Calabash::Cucumber::Gestures::Performer

        require "calabash-cucumber/uia"
        include Calabash::Cucumber::UIA

        require "calabash-cucumber/connection_helpers"
        include Calabash::Cucumber::ConnectionHelpers

        require "calabash-cucumber/query_helpers"
        include Calabash::Cucumber::QueryHelpers

        require "calabash-cucumber/status_bar_helpers"
        include Calabash::Cucumber::StatusBarHelpers

        require "calabash-cucumber/rotation_helpers"
        include Calabash::Cucumber::RotationHelpers

        require "calabash-cucumber/map"

        # @!visibility private
        UIA_STRATEGIES = [:preferences, :host, :shared_element]

        attr_reader :run_loop

        # @!visibility private
        def self.expect_valid_init_args(args)
          if args.nil?
            raise(ArgumentError, "Expected non-nil argument for initializer")
          end

          if !args.is_a?(Array)
            raise(ArgumentError, "Expected an array argument for initializer")
          end

          run_loop = args[0]

          if run_loop.nil?
            raise(ArgumentError,
%Q[Expected first element of args to be non-nil:

args = #{args}

])
          end

          if args.count != 1
            raise(ArgumentError,
%Q[Expected args to have exactly one element but found:

args = #{args}
])
          end

          self.expect_valid_run_loop(run_loop)
        end

        # @!visibility private
        def self.expect_valid_run_loop(run_loop)
          if run_loop.nil?
            raise(ArgumentError, "Expected run_loop arg to be non-nil")
          end

          if !run_loop.is_a?(Hash)
            raise(ArgumentError, %Q[
Expected run_loop arg to be a hash, but found:

run_loop = #{run_loop} is_a => #{run_loop.class}

])
          end

          performer = run_loop[:gesture_performer]
          # TODO Can remove the performer existence check after run-loop > 2.1.3
          if performer && performer != :instruments
            raise(ArgumentError, %Q[
Invalid :gesture_performer. Expected :instruments but found:

#{performer}

in

#{run_loop}

])
          end

          [:pid, :udid, :index, :log_file, :uia_strategy].each do |key|
            if !run_loop[key]
              raise(ArgumentError, %Q[
Expected run_loop to have a truthy value for :#{key} but found:

#{run_loop}

])
            end
          end

          strategy = run_loop[:uia_strategy]
          if !self.valid_uia_strategy?(strategy)
             raise(ArgumentError, %Q[
Expected '#{strategy}' to be one of these supported strategies:

#{UIA_STRATEGIES}

])
          end
          true
        end

        # @!visibility private
        def self.valid_uia_strategy?(strategy)
         UIA_STRATEGIES.include?(strategy)
        end

        # @!visibility private
        def initialize(*args)
          Instruments.expect_valid_init_args(args)
          @run_loop = args[0]
        end

        # @!visibility private
        def name
          :instruments
        end

        # @!visibility private
        def touch(options)
          query_action(options, :uia_tap_offset)
        end

        # @!visibility private
        def double_tap(options)
          query_action(options, :uia_double_tap_offset)
        end

        # @!visibility private
        def two_finger_tap(options)
          query_action(options, :uia_two_finger_tap_offset)
        end

        # @!visibility private
        def flick(options)
          query_action(options) do |offset|
            delta = {:offset => options[:delta] || {}}
            uia_flick_offset(offset, point_from(offset, delta))
          end
        end

        # @!visibility private
        def touch_hold(options)
          query_action(options) do |offset|
            duration = options[:duration] || 3
            uia_touch_hold_offset(duration, offset)
          end
        end

        # @!visibility private
        def swipe(options)
          query_action(options, :uia_swipe_offset, options)
        end

        # @!visibility private
        def pan(from, to, options={})
          query_action(:query => from) do |from_offset|
            query_action(:query => to) do |to_offset|
              uia_pan_offset(from_offset, to_offset, options)
            end
          end
        end

        # @!visibility private
        def pan_coordinates(from, to, options={})
          uia_pan_offset(from, to, options)
          [find_and_normalize("*")]
        end

        # @!visibility private
        def pinch(in_out, options)
          query_action(options) do |offset|
            options[:duration] = options[:duration] || 0.5
            uia_pinch_offset(in_out, offset, options)
          end
        end

        # @!visibility private
        def send_app_to_background(secs)
          uia_send_app_to_background(secs)
        end

        # @!visibility private
        def enter_text_with_keyboard(string, existing_text="")
          uia_type_string(string, existing_text)
        end

        # @!visibility private
        def fast_enter_text(text)
          uia_set_responder_value(text)
        end

        # @!visibility private
        # It is the caller's responsibility to ensure the keyboard is visible.
        def enter_char_with_keyboard(char)
          uia("uia.keyboard().typeString('#{char}')")
        end

        # @!visibility private
        def char_for_keyboard_action(action_key)
          SPECIAL_ACTION_CHARS[action_key]
        end

        # @!visibility private
        # TODO Implement this in JavaScript?
        # See the device_agent implementation of tap_keyboard_action_key and
        # the tap_keyboard_delete_key of this class.
        def tap_keyboard_action_key
          code = char_for_keyboard_action("Return")
          enter_char_with_keyboard(code)
        end

        # @!visibility private
        def tap_keyboard_delete_key
          js_tap_delete = %Q[(function() {
var deleteElement = uia.keyboard().elements().firstWithName('Delete');
if (deleteElement.isValid()) {
  deleteElement.tap();
} else {
  uia.keyboard().elements().firstWithName('delete').tap();
}
})();].gsub!($-0, "")

          uia(js_tap_delete)
        end

        # @!visibility private
        def dismiss_ipad_keyboard
          js = %Q[#{query_uia_hide_keyboard_button}.tap()]
          uia(js)
        end

        # @!visibility private
        def rotate(direction)
          current_orientation = status_bar_orientation.to_sym
          result = rotate_with_uia(direction, current_orientation)
          recalibrate_after_rotation
          ap result if RunLoop::Environment.debug?
          status_bar_orientation.to_sym
        end

        # @!visibility private
        def rotate_home_button_to(position)
          rotate_to_uia_orientation(position)
          recalibrate_after_rotation
          status_bar_orientation.to_sym
        end

        private

        # @!visibility private
        #
        # Calls #point_from which applies any :offset supplied in the options.
        def query_for_coordinates(options)
          ui_query = options[:query]

          first_element, orientation = first_element_for_query(ui_query)

          if first_element.nil?
            msg = %Q[
Could not find any views with query:

#{ui_query}

Try adjusting your query to return at least one view.

]
            Calabash::Cucumber::Map.new.screenshot_and_raise(msg)
          else

            normalize_rect_for_orientation!(orientation, first_element)

            {
              :coordinates => point_from(first_element, options),
              :view => first_element
            }
          end
        end

        # @!visibility private
        def first_element_for_query(ui_query)
          # Will raise if response "outcome" is not SUCCESS
          raw = Calabash::Cucumber::Map.raw_map(ui_query, :query)
          results = raw["results"]
          orientation = raw["status_bar_orientation"]

          if results.empty?
            return nil, nil
          else
            return results[0], orientation
          end
        end

        # @!visibility private
        # Data interface
        # options[:query] or options[:offset]
        def query_action(options, action=nil, *args, &block)
          ui_query = options[:query]
          offset = options[:offset]
          if ui_query
            res = find_and_normalize(ui_query)
            return res if res.empty?
            el = res.first
            final_offset = point_from(el, options)
            if block_given?
              yield final_offset
            else
              self.send(action, final_offset, *args)
            end
            [el]
          else
            ##implies offset
            if block_given?
              yield offset
            else
              self.send(action, offset, *args)
            end
          end
        end

        # @!visibility private
        def find_and_normalize(ui_query)
          raw_result = Calabash::Cucumber::Map.raw_map(ui_query, :query)
          orientation = raw_result["status_bar_orientation"]
          res = raw_result["results"]

          return res if res.empty?

          first_res = res.first
          normalize_rect_for_orientation!(orientation, first_res["rect"]) if first_res["rect"]

          res
        end

        # @!visibility private
        def normalize_rect_for_orientation!(orientation, rect)
          orientation = orientation.to_sym
          launcher = Calabash::Cucumber::Launcher.launcher
          device = launcher.device

          # Coordinate translations for orientation is handled in the server for iOS 8+
          if device.ios_major_version.to_i >= 8
            return
          end

          # We cannot use Device#screen_dimensions here because on iPads the height
          # and width are the opposite of what we expect.
          # @todo Move all coordinate/orientation translation into the server.
          if device.ipad?
            screen_size = { :width => 768, :height => 1024 }
          elsif device.iphone_4in?
            screen_size = { :width => 320, :height => 568 }
          else
            screen_size = { :width => 320, :height => 480 }
          end

          case orientation
            when :right
              cx = rect["center_x"]
              rect["center_x"] = rect["center_y"]
              rect["center_y"] = screen_size[:width] - cx
            when :left
              cx = rect["center_x"]
              rect["center_x"] = screen_size[:height] - rect["center_y"]
              rect["center_y"] = cx
            when :up
              cy = rect["center_y"]
              cx = rect["center_x"]
              rect["center_y"] = screen_size[:height] - cy
              rect["center_x"] = screen_size[:width] - cx
            else
              # no-op by design.
          end
        end

        # @!visibility private
        def recalibrate_after_rotation
          uia_query :window
        end

        # @!visibility private
        def rotate_to_uia_orientation(orientation)
          case orientation
            when :down then key = :portrait
            when :up then key = :upside_down
            when :left then key = :landscape_right
            when :right then key = :landscape_left
            else
              raise ArgumentError,
                    "Expected '#{orientation}' to be :left, :right, :up, or :down"
          end
          value = orientation_for_key(key)
          cmd = "UIATarget.localTarget().setDeviceOrientation(#{value})"
          uia(cmd)
        end

        # @!visibility private
        def rotate_with_uia(direction, current_orientation)
          key = orientation_key(direction, current_orientation)
          value = orientation_for_key(key)
          cmd = "UIATarget.localTarget().setDeviceOrientation(#{value})"
          uia(cmd)
        end

        # @!visibility private
        # Returns a query string for finding the iPad 'Hide keyboard' button.
        def query_uia_hide_keyboard_button
          "uia.keyboard().buttons()['Hide keyboard']"
        end

        # @!visibility private
        #
        # Don't change the single single quotes.
        SPECIAL_ACTION_CHARS = {
          "Delete" => '\b',
          "Return" => '\n'
        }
      end
    end
  end
end

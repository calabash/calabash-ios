# @!visibility private
module Calabash
  module Cucumber
    module Gestures

      require "calabash-cucumber/gestures/performer"

      # @!visibility private
      class DeviceAgent < Calabash::Cucumber::Gestures::Performer

        require "run_loop"
        require "calabash-cucumber/map"

        require "calabash-cucumber/query_helpers"
        include Calabash::Cucumber::QueryHelpers

        require "calabash-cucumber/status_bar_helpers"
        include Calabash::Cucumber::StatusBarHelpers

        require "calabash-cucumber/rotation_helpers"
        include Calabash::Cucumber::RotationHelpers

        require "calabash-cucumber/environment_helpers"
        include Calabash::Cucumber::EnvironmentHelpers

        # @!visibility private
        def self.expect_valid_args(args)
          if args.nil?
            raise ArgumentError, "Expected args to be a non-nil Array"
          end

          if !args.is_a?(Array)
            raise ArgumentError, %Q[Expected args to be an Array, found:

args = #{args}

]
          end

          if args.count != 1
            raise(ArgumentError,
                  %Q[Expected args to be an Array with one element, found:

args = #{args}

])
          end

          if !args[0].is_a?(RunLoop::XCUITest)
            raise(ArgumentError,
                  %Q[Expected first element of args to be a RunLoop::XCUITest instance, found:

args[0] = #{args[0]}

])
          end

          true
        end

        # @!visibility private
        def self.name
          :device_agent
        end

        attr_reader :device_agent

        # @!visibility private
        def initialize(*args)
          DeviceAgent.expect_valid_args(args)
          @device_agent = args[0]
        end

        def session_delete
          device_agent.send(:session_delete)
        end

        # @!visibility private
        def touch(options)
          hash = query_for_coordinates(options)

          device_agent.perform_coordinate_gesture("touch",
                                                  hash[:coordinates][:x],
                                                  hash[:coordinates][:y])
          [hash[:view]]
        end

        # @!visibility private
        def double_tap(options)
          hash = query_for_coordinates(options)
          device_agent.perform_coordinate_gesture("double_tap",
                                                  hash[:coordinates][:x],
                                                  hash[:coordinates][:y])
          [hash[:view]]
        end

        # @!visibility private
        def two_finger_tap(options)
          hash = query_for_coordinates(options)
          device_agent.perform_coordinate_gesture("two_finger_tap",
                                                  hash[:coordinates][:x],
                                                  hash[:coordinates][:y])
          [hash[:view]]
        end

        # @!visibility private
        def touch_hold(options)
          hash = query_for_coordinates(options)

          duration = options[:duration] || 3
          device_agent.perform_coordinate_gesture("touch",
                                                  hash[:coordinates][:x],
                                                  hash[:coordinates][:y],
                                                  {:duration => duration})
          [hash[:view]]
        end

        # @!visibility private
        def enter_text_with_keyboard(string, options={})
          device_agent.enter_text(string)
        end

        # @!visibility private
        def enter_char_with_keyboard(char)
          device_agent.enter_text(char)
        end

        # @!visibility private
        def char_for_keyboard_action(action_key)
          SPECIAL_ACTION_CHARS[action_key]
        end

        # @!visibility private
        def tap_keyboard_action_key
          mark = mark_for_return_key_of_first_responder
          if mark
            begin
              # The underlying query for coordinates always expects results.
              value = device_agent.touch(mark)
              return value
            rescue RuntimeError => e
              RunLoop.log_debug("Cannot find mark '#{mark}' with query; will send a newline")
            end
          else
            RunLoop.log_debug("Cannot find keyboard return key type; sending a newline")
          end

          code = char_for_keyboard_action("Return")
          device_agent.enter_text(code)
        end

        # @!visibility private
        def tap_keyboard_delete_key
          device_agent.touch("delete")
        end

        # @!visibility private
        def fast_enter_text(text)
          device_agent.enter_text(text)
        end

        # @!visibility private
        #
        # Stable across different keyboard languages.
        def dismiss_ipad_keyboard
          device_agent.touch("Hide keyboard")
        end

        # @!visibility private
        def rotate(direction)
          # Caller is responsible for normalizing and verifying direction.
          current_orientation = status_bar_orientation.to_sym
          key = orientation_key(direction, current_orientation)
          position = orientation_for_key(key)
          rotate_home_button_to(position)
        end

        # @!visibility private
        def rotate_home_button_to(position)
          # Caller is responsible for normalizing and verifying position.
          @device_agent.rotate_home_button_to(position)
          status_bar_orientation.to_sym
        end

        private

        # @!visibility private
        #
        # Calls #point_from which applies any :offset supplied in the options.
        def query_for_coordinates(options)
          ui_query = options[:query]

          first_element = first_element_for_query(ui_query)

          if first_element.nil?
            msg = %Q[
Could not find any views with query:

#{ui_query}

Try adjusting your query to return at least one view.

]
            Calabash::Cucumber::Map.new.screenshot_and_raise(msg)
          else
            {
              :coordinates => point_from(first_element),
              :view => first_element
            }
          end
        end

        # @!visibility private
        def first_element_for_query(ui_query)
          # Will raise if response "outcome" is not SUCCESS
          results = Calabash::Cucumber::Map.raw_map(ui_query, :query)["results"]

          if results.empty?
            nil
          else
            results[0]
          end
        end

        # @!visibility private
        #
        # Don't change the double quotes.
        SPECIAL_ACTION_CHARS = {
          "Delete" => "\b",
          "Return" => "\n"
        }.freeze

        # @!visibility private
        #
        # Keys are from the UIReturnKeyType enum.
        #
        # The values are localization independent identifiers - these are
        # stable across localizations and keyboard languages.  The exception is
        # Continue which is not stable.
        RETURN_KEY_TYPE = {
          0 => "Return",
          1 => "Go",
          2 => "Google",
          # Needs special physical device vs simulator handling.
          3 => "Join",
          4 => "Next",
          5 => "Route",
          6 => "Search",
          7 => "Send",
          8 => "Yahoo",
          9 => "Done",
          10 => "Emergency call",
          # https://xamarin.atlassian.net/browse/TCFW-344
          # Localized!!! Apple bug.
          11 => "Continue"
        }.freeze

        # @!visibility private
        def mark_for_return_key_type(number)
          # https://xamarin.atlassian.net/browse/TCFW-361
          value = RETURN_KEY_TYPE[number]
          if value == "Join" && !simulator?
            "Join:"
          else
            value
          end
        end

        # @!visibility private
        def return_key_type_of_first_responder

          ['textField', 'textView'].each do |ui_class|
            query = "#{ui_class} isFirstResponder:1"
            raw = Calabash::Cucumber::Map.raw_map(query, :query, :returnKeyType)
            results = raw["results"]
            if !results.empty?
              return results.first
            end
          end

          RunLoop.log_debug("Cannot find keyboard first responder to ask for its returnKeyType")
          nil
        end

        # @!visibility private
        def mark_for_return_key_of_first_responder
          number = return_key_type_of_first_responder
          mark_for_return_key_type(number)
        end
      end
    end
  end
end

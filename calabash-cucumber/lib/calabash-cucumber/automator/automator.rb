module Calabash
  module Cucumber
    # @!visibility private
    module Automator
      # @!visibility private
      class Automator

        require "calabash-cucumber/abstract"
        include Calabash::Cucumber::Abstract


        # @!visibility private
        def initialize(*args)
          abstract_method!
        end

        # @!visibility private
        def name
          abstract_method!
        end

        # @!visibility private
        def stop
          abstract_method!
        end

        # @!visibility private
        def running?
          abstract_method!
        end

        # @!visibility private
        def client
          abstract_method!
        end

        # @!visibility private
        def touch(options)
          abstract_method!
        end

        # @!visibility private
        def double_tap(options)
          abstract_method!
        end

        # @!visibility private
        def two_finger_tap(options)
          abstract_method!
        end

        # @!visibility private
        def touch_hold(options)
          abstract_method!
        end

        # @!visibility private
        def flick(options)
          abstract_method!
        end

        # @!visibility private
        def swipe(direction, options={})
          abstract_method!
        end

        # @!visibility private
        #
        # Callers must validate the options.
        def pan(from_query, to_query, options={})
          abstract_method!
        end

        # @!visibility private
        #
        # Callers must validate the options.
        def pan_coordinates(from_point, to_point, options={})
          abstract_method!
        end

        # @!visibility private
        def pinch(in_or_out, options)
          abstract_method!
        end

        # @!visibility private
        def send_app_to_background(seconds)
          abstract_method!
        end

        # @!visibility private
        #
        # It is the caller's responsibility to:
        # 1. expect the keyboard is visible
        # 2. escape the existing text
        def enter_text_with_keyboard(string, options={})
          abstract_method!
        end

        # @!visibility private
        #
        # Respond to keys like 'Delete' or 'Return'.
        def char_for_keyboard_action(action_key)
          abstract_method!
        end

        # @!visibility private
        # It is the caller's responsibility to ensure the keyboard is visible.
        def enter_char_with_keyboard(char)
          abstract_method!
        end

        # @!visibility private
        # It is the caller's responsibility to ensure the keyboard is visible.
        def tap_keyboard_action_key
          abstract_method!
        end

        # @!visibility private
        # It is the caller's responsibility to ensure the keyboard is visible.
        def tap_keyboard_delete_key
          abstract_method!
        end

        # @!visibility private
        #
        # Legacy API - can we remove this method?
        #
        # It is the caller's responsibility to ensure the keyboard is visible.
        def fast_enter_text(text)
          abstract_method!
        end

        # @!visibility private
        #
        # Caller is responsible for limiting calls to iPads and waiting for the
        # keyboard to disappear.
        def dismiss_ipad_keyboard
          abstract_method!
        end

        # @!visibility private
        #
        # Caller is responsible for providing a valid direction.
        def rotate(direction)
          abstract_method!
        end

        # @!visibility private
        #
        # Caller is responsible for normalizing and validating the position.
        def rotate_home_button_to(position)
          abstract_method!
        end
      end
    end
  end
end

require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/environment_helpers'

module Calabash
  module Cucumber

    # Raised when there is a problem involving a keyboard mode.  There are
    # three keyboard modes:  docked, split, and undocked.
    #
    # All iPads support these keyboard modes, but the user can disable them
    # in Settings.app.
    #
    # The iPhone 6+ family also supports keyboard modes, but Calabash does
    # support keyboard modes on these devices.
    class KeyboardModeError < StandardError; ; end

    # Collection of methods for interacting with the keyboard.
    #
    # We've gone to great lengths to provide the fastest keyboard entry possible.
    module KeyboardHelpers

      include Calabash::Cucumber::TestsHelpers

      # @!visibility private
      # noinspection RubyStringKeysInHashInspection
      SPECIAL_ACTION_CHARS = {
            'Delete' => '\b',
            'Return' => '\n'
            # these are not supported yet and I am pretty sure that they
            # cannot be touched by passing an escaped character and instead
            # the must be found using UIAutomation calls.  -jmoody
            #'Dictation' => nil,
            #'Shift' => nil,
            #'International' => nil,
            #'More' => nil,
      }

      # @!visibility private
      # Returns a query string for detecting a keyboard.
      def _qstr_for_keyboard
        "view:'UIKBKeyplaneView'"
      end

      # Returns true if a docked keyboard is visible.
      #
      # A docked keyboard is pinned to the bottom of the view.
      #
      # Keyboards on the iPhone and iPod are docked.
      #
      # @return [Boolean] if a keyboard is visible and docked.
      def docked_keyboard_visible?
        res = query(_qstr_for_keyboard).first

        return false if res.nil?

        return true if device_family_iphone?

        orientation = status_bar_orientation.to_sym
        keyboard_height = res['rect']['height']
        keyboard_y = res['rect']['y']
        scale = screen_dimensions[:scale]

        if orientation == :left || orientation == :right
          screen_height = screen_dimensions[:width]/scale
        else
          screen_height = screen_dimensions[:height]/scale
        end

        screen_height - keyboard_height == keyboard_y
      end

      # Returns true if an undocked keyboard is visible.
      #
      # A undocked keyboard is floats in the middle of the view.
      #
      # @return [Boolean] Returns false if the device is not an iPad; all
      # keyboards on the iPhone and iPod are docked.
      def undocked_keyboard_visible?
        return false if device_family_iphone?

        res = query(_qstr_for_keyboard).first
        return false if res.nil?

        not docked_keyboard_visible?
      end

      # Returns true if a split keyboard is visible.
      #
      # A split keyboard is floats in the middle of the view and is split to
      # allow faster thumb typing
      #
      # @return [Boolean] Returns false if the device is not an iPad; all
      # keyboards on the Phone and iPod are docked and not split.
      def split_keyboard_visible?
        return false if device_family_iphone?
        query("view:'UIKBKeyView'").count > 0 and
              element_does_not_exist(_qstr_for_keyboard)
      end

      # Returns true if there is a visible keyboard.
      #
      # @return [Boolean] Returns true if there is a visible keyboard.
      def keyboard_visible?
        docked_keyboard_visible? ||
          undocked_keyboard_visible? ||
          split_keyboard_visible?
      end

      # Waits for a keyboard to appear and once it does appear waits for
      # `:post_timeout` seconds.
      #
      # @see Calabash::Cucumber::WaitHelpers#wait_for for other options this
      #  method can handle.
      #
      # @param [Hash] options controls the `wait_for` behavior
      # @option opts [String] :timeout_message ('keyboard did not appear')
      #  Controls the message that appears in the error.
      # @option opts [Number] :post_timeout (0.3) Controls how long to wait
      #  _after_ the keyboard has appeared.
      #
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] if no keyboard appears
      def wait_for_keyboard(options={})
        default_opts = {
          :timeout_message => "Keyboard did not appear",
          :post_timeout => 0.3
        }

        merged_opts = default_opts.merge(options)
        wait_for(merged_opts) do
          keyboard_visible?
        end
      end

      # @!visibility private
      # returns an array of possible ipad keyboard modes
      def _ipad_keyboard_modes
        [:docked, :undocked, :split]
      end

      # Returns the keyboard mode.
      #
      # @example How to use in a wait_* function.
      #  wait_for do
      #   ipad_keyboard_mode({:raise_on_no_visible_keyboard => false}) == :split
      #  end
      #
      # ```
      #                   keyboard is pinned to bottom of the view #=> :docked
      #             keyboard is floating in the middle of the view #=> :undocked
      #                             keyboard is floating and split #=> :split
      #     no keyboard and :raise_on_no_visible_keyboard == false #=> :unknown
      # ```
      #
      # @raise [RuntimeError] if the device under test is not an iPad.
      #
      # @raise [RuntimeError] if `:raise_on_no_visible_keyboard` is truthy and
      #  no keyboard is visible.
      # @param [Hash] opts controls the runtime behavior.
      # @option opts [Boolean] :raise_on_no_visible_keyboard (true) set to false
      #  if you don't want to raise an error.
      # @return [Symbol] Returns one of `{:docked | :undocked | :split | :unknown}`
      def ipad_keyboard_mode(opts = {})
        if device_family_iphone?
          raise "There are no keyboard modes for iPhones or iPods"
        end

        default_opts = {:raise_on_no_visible_keyboard => true}
        merged_opts = default_opts.merge(opts)
        if merged_opts[:raise_on_no_visible_keyboard]
          screenshot_and_raise "There is no visible keyboard" unless keyboard_visible?
          return :docked if docked_keyboard_visible?
          return :undocked if undocked_keyboard_visible?
          :split
        else
          return :docked if docked_keyboard_visible?
          return :undocked if undocked_keyboard_visible?
          return :split if split_keyboard_visible?
          :unknown
        end
      end

      # @!visibility private
      # Raises an error ir the keyboard is not visible.
      def expect_keyboard_visible!
        if !keyboard_visible?
          screenshot_and_raise "Keyboard is not visible"
        end
      end

      # @!visibility private
      # Returns the activation point of the iPad keyboard mode key.
      #
      # The mode key is also known as the 'Hide keyboard' key.
      #
      # @note
      #  This is only available when running under instruments.
      #
      # @raise [RuntimeError] when the device is not an iPad
      # @raise [RuntimeError] the app was not launched with instruments
      def _point_for_ipad_keyboard_mode_key
        raise "The keyboard mode does not exist on the on the iphone" if device_family_iphone?
        res = send_uia_command({:command => "#{_query_uia_hide_keyboard_button}.rect()"})
        origin = res['value']['origin']
        {:x => origin['x'], :y => origin['y']}
      end

      # @!visibility private
      # Touches the bottom option on the popup dialog that is presented when the
      # the iPad keyboard `mode` key is touched and held.
      #
      # The `mode` key is also know as the 'Hide keyboard' key.
      #
      # The `mode` key allows the user to undock, dock, or split the keyboard.
      def _touch_bottom_keyboard_mode_row
        start_pt = _point_for_ipad_keyboard_mode_key
        # there are 10 pt btw the key and the popup and the row is 50 pt
        y_offset = 10 + 25
        end_pt = {:x => (start_pt[:x] - 40), :y => (start_pt[:y] - y_offset)}
        uia_pan_offset(start_pt, end_pt, {})
        sleep(1.0)
      end

      # Touches the top option on the popup dialog that is presented when the
      # the iPad keyboard mode key is touched and held.
      #
      # The `mode` key is also know as the 'Hide keyboard' key.
      #
      # The `mode` key allows the user to undock, dock, or split the keyboard.
      def _touch_top_keyboard_mode_row
        start_pt = _point_for_ipad_keyboard_mode_key
        # there are 10 pt btw the key and the popup and each row is 50 pt
        # NB: no amount of offsetting seems to allow touching the top row
        #     when the keyboard is split

        x_offset = 40
        y_offset = 10 + 50 + 25
        end_pt = {:x => (start_pt[:x] - x_offset), :y => (start_pt[:y] - y_offset)}
        uia_pan_offset(start_pt, end_pt, {:duration => 1.0})
      end

      # Ensures that the iPad keyboard is docked.
      #
      # Docked means the keyboard is pinned to bottom of the view.
      #
      # If the device is not an iPad, this is behaves like a call to
      # `wait_for_keyboard`.
      #
      # @raise [RuntimeError] if there is no visible keyboard
      # @raise [RuntimeError] a docked keyboard was not achieved
      def ensure_docked_keyboard
        wait_for_keyboard

        return if device_family_iphone?

        mode = ipad_keyboard_mode

        return if mode == :docked

        if ios9?
          raise KeyboardModeError,
                'Changing keyboard modes is not supported on iOS 9'
        else
          case mode
            when :split then
              _touch_bottom_keyboard_mode_row
            when :undocked then
              _touch_top_keyboard_mode_row
            when :docked then
              # already docked
            else
              screenshot_and_raise "expected '#{mode}' to be one of #{_ipad_keyboard_modes}"
          end
        end

        begin
          wait_for({:post_timeout => 1.0}) do
            docked_keyboard_visible?
          end
        rescue
          mode = ipad_keyboard_mode
          o = status_bar_orientation
          screenshot_and_raise "expected keyboard to be ':docked' but found '#{mode}' in orientation '#{o}'"
        end
      end

      # Ensures that the iPad keyboard is undocked.
      #
      # Undocked means the keyboard is floating in the middle of the view.
      #
      # If the device is not an iPad, this is behaves like a call to
      # `wait_for_keyboard`.
      #
      # If the device is not an iPad, this is behaves like a call to
      # `wait_for_keyboard`.
      #
      # @raise [RuntimeError] if there is no visible keyboard
      # @raise [RuntimeError] an undocked keyboard was not achieved
      def ensure_undocked_keyboard
        wait_for_keyboard

        return if device_family_iphone?

        mode = ipad_keyboard_mode

        return if mode == :undocked

        if ios9?
          raise KeyboardModeError,
                "Changing keyboard modes is not supported on iOS 9"
        else
          case mode
            when :split then
              # keep these condition separate because even though they do the same
              # thing, the else condition is a hack
              if ios5?
                # iOS 5 has no 'Merge' feature in split keyboard, so dock first then
                # undock from docked mode
                _touch_bottom_keyboard_mode_row
                _wait_for_keyboard_in_mode(:docked)
              else
                # in iOS > 5, it seems to be impossible consistently touch the
                # the top keyboard mode popup button, so we punt
                _touch_bottom_keyboard_mode_row
                _wait_for_keyboard_in_mode(:docked)
              end
              _touch_top_keyboard_mode_row
            when :undocked then
              # already undocked
            when :docked then
              _touch_top_keyboard_mode_row
            else
              screenshot_and_raise "expected '#{mode}' to be one of #{_ipad_keyboard_modes}"
          end
        end
        _wait_for_keyboard_in_mode(:undocked)
      end

      # Ensures that the iPad keyboard is split.
      #
      # Split means the keyboard is floating in the middle of the view and is
      # split into two sections to enable faster thumb typing.
      #
      # If the device is not an iPad, this is behaves like a call to
      # `wait_for_keyboard`.
      #
      # If the device is not an iPad, this is behaves like a call to
      # `wait_for_keyboard`.
      #
      # @raise [RuntimeError] if there is no visible keyboard
      # @raise [RuntimeError] a split keyboard was not achieved
      def ensure_split_keyboard
        wait_for_keyboard

        return if device_family_iphone?

        mode = ipad_keyboard_mode

        return if mode == :split

        if ios9?
          raise KeyboardModeError,
                "Changing keyboard modes is not supported on iOS 9"
        else
          case mode
            when :split then
              # already split
            when :undocked then
              _touch_bottom_keyboard_mode_row
            when :docked then
              _touch_bottom_keyboard_mode_row
            else
              screenshot_and_raise "expected '#{mode}' to be one of #{_ipad_keyboard_modes}"
          end
        end
        _wait_for_keyboard_in_mode(:split)
      end

      # @!visibility private
      def _wait_for_keyboard_in_mode(mode, opts={})
        default_opts = {:post_timeout => 1.0}
        opts = default_opts.merge(opts)
        begin
          wait_for(opts) do
            case mode
              when :split then
                split_keyboard_visible?
              when :undocked
                undocked_keyboard_visible?
              when :docked
                docked_keyboard_visible?
              else
                screenshot_and_raise "expected '#{mode}' to be one of #{_ipad_keyboard_modes}"
            end
          end
        rescue
          actual = ipad_keyboard_mode
          o = status_bar_orientation
          screenshot_and_raise "expected keyboard to be '#{mode}' but found '#{actual}' in orientation '#{o}'"
        end
      end

      # Used for detecting keyboards that are not normally visible to calabash;
      # e.g. the keyboard on the `MFMailComposeViewController`
      #
      # @note
      #  IMPORTANT this should only be used when the app does not respond to
      #  `keyboard_visible?`.
      #
      # @see #keyboard_visible?
      #
      # @raise [RuntimeError] if the app was not launched with instruments
      def uia_keyboard_visible?
        res = uia_query_windows(:keyboard)
        not res.eql?(':nil')
      end

      # Waits for a keyboard that is not normally visible to calabash;
      # e.g. the keyboard on `MFMailComposeViewController`.
      #
      # @note
      #  IMPORTANT this should only be used when the app does not respond to
      #  `keyboard_visible?`.
      #
      # @see #keyboard_visible?
      #
      # @raise [RuntimeError] if the app was not launched with instruments
      def uia_wait_for_keyboard(opts={})
        default_opts = {:timeout => 10,
                        :retry_frequency => 0.1,
                        :post_timeout => 0.5}
        opts = default_opts.merge(opts)
        unless opts[:timeout_message]
          msg = "waited for '#{opts[:timeout]}' for keyboard"
          opts[:timeout_message] = msg
        end

        wait_for(opts) do
          uia_keyboard_visible?
        end
      end

      # Waits for a keyboard to appear and returns the localized name of the
      # `key_code` signifier
      #
      # @param [String] key_code Maps to a specific name in some localization
      def lookup_key_name(key_code)
        wait_for_keyboard
        begin
          response_json = JSON.parse(http(:path => 'keyboard-language'))
        rescue JSON::ParserError
          raise RuntimeError, "Could not parse output of keyboard-language route. Did the app crash?"
        end
        if response_json['outcome'] != 'SUCCESS'
          screenshot_and_raise "failed to retrieve the keyboard localization"
        end
        localized_lang = response_json['results']['input_mode']
        RunLoop::L10N.new.lookup_localization_name(key_code, localized_lang)
      end

      # @!visibility private
      # Returns the the text in the first responder.
      #
      # The first responder will be the UITextField or UITextView instance
      # that is associated with the visible keyboard.
      #
      # Returns empty string if no textField or textView elements are found to be
      # the first responder.
      #
      # @raise [RuntimeError] if there is no visible keyboard
      def _text_from_first_responder
        raise 'there must be a visible keyboard' unless keyboard_visible?

        ['textField', 'textView'].each do |ui_class|
          res = query("#{ui_class} isFirstResponder:1", :text)
          return res.first unless res.empty?
        end
        #noinspection RubyUnnecessaryReturnStatement
        return ''
      end

      private

      # @!visibility private
      # Returns a query string for finding the iPad 'Hide keyboard' button.
      def _query_uia_hide_keyboard_button
        "uia.keyboard().buttons()['Hide keyboard']"
      end
    end
  end
end

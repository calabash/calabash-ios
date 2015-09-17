require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/playback_helpers'
require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber
    # Collection of methods for interacting with the keyboard.
    #
    # We've gone to great lengths to provide the fastest keyboard entry possible.
    #
    # If you are having trouble with skipped or are receiving JSON octet
    # errors when typing, you might be able to resolve the problems by slowing
    # down the rate of typing.
    #
    # Example:  Use keyboard_enter_char + :wait_after_char.
    #
    # ```
    # str.each_char do |char|
    #   # defaults to 0.05 seconds
    #   keyboard_enter_char(char, `{wait_after_char:0.5}`)
    # end
    # ```
    #
    # Example:  Use keyboard_enter_char + POST_ENTER_KEYBOARD
    #
    # ```
    # $ POST_ENTER_KEYBOARD=0.1 bundle exec cucumber
    # str.each_char do |char|
    #   # defaults to 0.05 seconds
    #   keyboard_enter_char(char)
    # end
    # ```
    #
    # @note
    #  We have an exhaustive set of keyboard related test.s  The API is reasonably
    #  stable.  We are fighting against known bugs in Apple's UIAutomation. You
    #  should only need to fall back to the examples below in unusual situations.
    module KeyboardHelpers

      include Calabash::Cucumber::TestsHelpers
      include Calabash::Cucumber::Logging

      # @!visibility private
      KEYPLANE_NAMES = {
          :small_letters => 'small-letters',
          :capital_letters => 'capital-letters',
          :numbers_and_punctuation => 'numbers-and-punctuation',
          :first_alternate => 'first-alternate',
          :numbers_and_punctuation_alternate => 'numbers-and-punctuation-alternate'
      }

      # @!visibility private
      # noinspection RubyStringKeysInHashInspection
      UIA_SUPPORTED_CHARS = {
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

        if orientation == :left || orientation == :right
          screen_height = screen_dimensions[:width]
        else
          screen_height = screen_dimensions[:height]
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
        docked_keyboard_visible? or undocked_keyboard_visible? or split_keyboard_visible?
      end

      # Waits for a keyboard to appear and once it does appear waits for
      # `:post_timeout` seconds.
      #
      # @see Calabash::Cucumber::WaitHelpers#wait_for for other options this
      #  method can handle.
      #
      # @param [Hash] opts controls the `wait_for` behavior
      # @option opts [String] :timeout_message ('keyboard did not appear')
      #  Controls the message that appears in the error.
      # @option opts [Number] :post_timeout (0.3) Controls how long to wait
      #  _after_ the keyboard has appeared.
      #
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] if no keyboard appears
      def wait_for_keyboard(opts={})
        default_opts = {:timeout_message => 'keyboard did not appear',
                        :post_timeout => 0.3}
        opts = default_opts.merge(opts)
        wait_for(opts) do
          keyboard_visible?
        end
      end

      # @deprecated 0.9.163 replaced with `wait_for_keyboard`
      # @see #wait_for_keyboard
      def await_keyboard
        _deprecated('0.9.163', "use 'wait_for_keyboard' instead", :warn)
        wait_for_keyboard
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
        raise 'the keyboard mode does not exist on the iphone or ipod' if device_family_iphone?

        default_opts = {:raise_on_no_visible_keyboard => true}
        merged_opts = default_opts.merge(opts)
        if merged_opts[:raise_on_no_visible_keyboard]
          screenshot_and_raise 'there is no visible keyboard' unless keyboard_visible?
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
      # Ensures that there is a keyboard to enter text.
      #
      # @note
      # *IMPORTANT* will always raise an error when the keyboard is split and
      # there is no `run_loop`; i.e. UIAutomation is not available.
      #
      # @param [Hash] opts controls screenshot-ing and error raising conditions
      # @option opts [Boolean] :screenshot (true) raise with a screenshot if
      #  a keyboard cannot be ensured
      # @option opts [Boolean] :skip (false) skip any checking (a nop) - used
      #  when iterating over keyplanes for keys
      def _ensure_can_enter_text(opts={})
        default_opts = {:screenshot => true,
                        :skip => false}
        opts = default_opts.merge(opts)
        return if opts[:skip]

        screenshot = opts[:screenshot]
        unless keyboard_visible?
          msg = 'no visible keyboard'
          if screenshot
            screenshot_and_raise msg
          else
            raise msg
          end
        end

        if split_keyboard_visible? and uia_not_available?
          msg = 'cannot type on a split keyboard without launching with Instruments'
          if screenshot
            screenshot_and_raise msg
          else
            raise msg
          end
        end
      end

      # Use keyboard to enter a character.
      #
      # @note
      #  IMPORTANT: Use the `POST_ENTER_KEYBOARD` environmental variable
      #  to slow down the typing; adds a wait after each character is touched.
      #  this can fix problems where the typing is too fast and characters are
      #  skipped.
      #
      # @note
      #  There are several special 'characters', some of which do not appear on
      #  all keyboards; e.g. `Delete`, `Return`.
      #
      # @note
      #  Since 0.9.163, this method accepts a Hash as the second parameter.  The
      #  previous second parameter was a Boolean that controlled whether or not
      #  to screenshot on errors.
      #
      # @see #keyboard_enter_text
      #
      # @note
      #  You should prefer to call `keyboard_enter_text`.
      #
      # @raise [RuntimeError] if there is no visible keyboard
      # @raise [RuntimeError] if the keyboard (layout) is not supported
      #
      # @param [String] chr the character to type
      # @param [Hash] opts options to control the behavior of the method
      # @option opts [Boolean] :should_screenshot (true) whether or not to
      #  screenshot on errors
      # @option opts [Float] :wait_after_char ('POST_ENTER_KEYBOARD' or 0.05)
      #  how long to wait after a character is typed.
      def keyboard_enter_char(chr, opts={})
        unless opts.is_a?(Hash)
         msg = "you should no longer pass a boolean as the second arg; pass {:should_screenshot => '#{opts}'}  hash instead"
         _deprecated('0.9.163', msg, :warn)
         opts = {:should_screenshot => opts}
        end

        default_opts = {:should_screenshot => true,
                        # introduce a small wait to avoid skipping characters
                        # keep this as short as possible
                        :wait_after_char => (ENV['POST_ENTER_KEYBOARD'] || 0.05).to_f}

        opts = default_opts.merge(opts)

        should_screenshot = opts[:should_screenshot]
        _ensure_can_enter_text({:screenshot => should_screenshot,
                                :skip => (not should_screenshot)})

        if uia_available?
          if chr.length == 1
            uia_type_string_raw chr
          else
            code = UIA_SUPPORTED_CHARS[chr]

            unless code
              raise "typing character '#{chr}' is not yet supported when running with Instruments"
            end

            # on iOS 6, the Delete char code is _not_ \b
            # on iOS 7, the Delete char code is \b on non-numeric keyboards
            #           on numeric keyboards, it is actually a button on the
            #           keyboard and not a key
            if code.eql?(UIA_SUPPORTED_CHARS['Delete'])
              uia("uia.keyboard().elements().firstWithName('Delete').tap()")
            else
              uia_type_string_raw(code)
            end
          end
          # noinspection RubyStringKeysInHashInspection
          res = {'results' => []}
        else
          res = http({:method => :post, :path => 'keyboard'},
                     {:key => chr, :events => load_playback_data('touch_done')})
          res = JSON.parse(res)
          if res['outcome'] != 'SUCCESS'
            msg = "Keyboard enter failed failed because: #{res['reason']}\n#{res['details']}"
            if should_screenshot
              screenshot_and_raise msg
            else
              raise msg
            end
          end
        end

        if ENV['POST_ENTER_KEYBOARD']
          w = ENV['POST_ENTER_KEYBOARD'].to_f
          if w > 0
            sleep(w)
          end
        end
        pause = opts[:wait_after_char]
        sleep(pause) if pause > 0
        res['results']
      end

      # Uses the keyboard to enter text.
      #
      # @param [String] text the text to type.
      # @raise [RuntimeError] if the text cannot be typed.
      def keyboard_enter_text(text)
        _ensure_can_enter_text
        if uia_available?
          text_before = _text_from_first_responder()
          text_before = text_before.gsub("\n","\\n") if text_before
          uia_type_string(text, text_before)
        else
          text.each_char do |ch|
            begin
              keyboard_enter_char(ch, {:should_screenshot => false})
            rescue
              _search_keyplanes_and_enter_char(ch)
            end
          end
        end
      end

      # @!visibility private
      #
      # Enters text into view identified by a query
      #
      # @note
      # *IMPORTANT* enter_text defaults to calling 'setValue' in UIAutomation
      # on the text field. This is fast, but in some cases might result in slightly
      # different behaviour than using `keyboard_enter_text`.
      # To force use of `keyboard_enter_text` in `enter_text` use
      # option :use_keyboard
      #
      # @param [String] uiquery the element to enter text into
      # @param [String] text the text to enter
      # @param [Hash] options controls details of text entry
      # @option options [Boolean] :use_keyboard (false) use the iOS keyboard
      #   to enter each character separately
      # @option options [Boolean] :wait (true) call wait_for_element_exists with uiquery
      # @option options [Hash] :wait_options ({}) if :wait pass this as options to wait_for_element_exists
      def enter_text(uiquery, text, options = {})
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

      # @!visibility private
      #
      # Enters text into current text input field
      #
      # @note
      # *IMPORTANT* fast_enter_text defaults to calling 'setValue' in UIAutomation
      # on the text field. This is fast, but in some cases might result in slightly
      # different behaviour than using `keyboard_enter_text`.
      # @param [String] text the text to enter
      def fast_enter_text(text)
        _ensure_can_enter_text
        if uia_available?
          uia_set_responder_value(text)
        else
          keyboard_enter_text(text)
        end
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
      # @raise [RuntimeError] if the text cannot be typed.
      def tap_keyboard_action_key
        keyboard_enter_char 'Return'
      end

      # @deprecated 0.10.0 replaced with `tap_keyboard_action_key`
      # @see #tap_keyboard_action_key
      #
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
      # @raise [RuntimeError] if the text cannot be typed.
      def done
        tap_keyboard_action_key
      end

      # @!visibility private
      # Returns the current keyplane.
      def _current_keyplane
        kp_arr = _do_keyplane(
            lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'componentName') },
            lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'name') })
        kp_arr.first.downcase
      end

      # @!visibility private
      # Searches the available keyplanes for chr and if it is found, types it.
      #
      # This is a recursive function.
      #
      # @note
      #   Use the `KEYPLANE_SEARCH_STEP_PAUSE` variable to control how quickly
      #   the next keyplane is searched.  Increase this value if you encounter
      #   problems with missed keystrokes.
      #
      # @note
      #   When running under instruments, this method is not called.
      #
      # @raise [RuntimeError] if the char cannot be found
      def _search_keyplanes_and_enter_char(chr, visited=Set.new)
        cur_kp = _current_keyplane
        begin
          keyboard_enter_char(chr, {:should_screenshot => false})
          return true #found
        rescue
          pause = (ENV['KEYPLANE_SEARCH_STEP_PAUSE'] || 0.2).to_f
          sleep (pause) if pause > 0

          visited.add(cur_kp)

          #figure out keyplane alternates
          props = _do_keyplane(
              lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'properties') },
              lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'attributes', 'dict') }
          ).first

          known = KEYPLANE_NAMES.values

          found = false
          keyplane_selection_keys = ['shift', 'more']
          keyplane_selection_keys.each do |key|
            sleep (pause) if pause > 0
            plane = props["#{key}-alternate"]
            if known.member?(plane) and (not visited.member?(plane))
              keyboard_enter_char(key.capitalize, {:should_screenshot => false})
              found = _search_keyplanes_and_enter_char(chr, visited)
              return true if found
              #not found => try with other keyplane selection key
              keyplane_selection_keys.delete(key)
              other_key = keyplane_selection_keys.last
              keyboard_enter_char(other_key.capitalize, {:should_screenshot => false})
              found = _search_keyplanes_and_enter_char(chr, visited)
              return true if found
            end
          end
          return false
        end
      end

      # @!visibility private
      # Process a keyplane.
      #
      # @raise [RuntimeError] if there is no visible keyplane
      def _do_keyplane(kbtree_proc, keyplane_proc)
        desc = query("view:'UIKBKeyplaneView'", 'keyplane')
        fail('No keyplane (UIKBKeyplaneView keyplane)') if desc.empty?
        fail('Several keyplanes (UIKBKeyplaneView keyplane)') if desc.count > 1
        kp_desc = desc.first
        if /^<UIKBTree/.match(kp_desc)
          #ios5+
          kbtree_proc.call
        elsif /^<UIKBKeyplane/.match(kp_desc)
          #ios4
          keyplane_proc.call
        end
      end

      # @!visibility private
      # Returns a query string for finding the iPad 'Hide keyboard' button.
      def _query_uia_hide_keyboard_button
        "uia.keyboard().buttons()['Hide keyboard']"
      end

      # Dismisses a iPad keyboard by touching the 'Hide keyboard' button and waits
      # for the keyboard to disappear.
      #
      # @note
      #  the dismiss keyboard key does not exist on the iPhone or iPod
      #
      # @raise [RuntimeError] if the device is not an iPad
      def dismiss_ipad_keyboard
        screenshot_and_raise 'cannot dismiss keyboard on iphone' if device_family_iphone?

        if uia_available?
          send_uia_command({:command =>  "#{_query_uia_hide_keyboard_button}.tap()"})
        else
          touch(_query_for_keyboard_mode_key)
        end

        opts = {:timeout_message => 'keyboard did not disappear'}
        wait_for(opts) do
          not keyboard_visible?
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
        raise 'the keyboard mode does not exist on the on the iphone' if device_family_iphone?
        raise 'cannot detect keyboard mode key without launching with instruments' unless uia_available?
        res = send_uia_command({:command => "#{_query_uia_hide_keyboard_button}.rect()"})
        origin = res['value']['origin']
        {:x => origin['x'], :y => origin['y']}
      end

      # @!visibility private
      # Returns a query string for touching one of the options that appears when
      # the iPad mode key is touched and held.
      #
      # The mode key is also know as the 'Hide keyboard' key.
      #
      # @note
      #  This is only available when running outside of instruments.
      #
      # @param [Symbol] top_or_bottom can be one of `{:top | :bottom}`
      # @param [Symbol] mode `{:docked | :undocked | :skipped}`
      #
      # @raise [RuntimeError] the device is not an iPad
      # @raise [RuntimeError] the app was not launched with instruments
      # @raise [RuntimeError] the method is passed invalid arguments
      def _query_for_touch_for_keyboard_mode_option(top_or_bottom, mode)
        raise 'the keyboard mode does not exist on the iphone' if device_family_iphone?

        if uia_available?
          raise "UIA is available, use '_point_for_keyboard_mode_key' instead"
        end

        valid = [:top, :bottom]
        unless valid.include? top_or_bottom
          raise "expected '#{top_or_bottom}' to be one of '#{valid}'"
        end

        valid = [:split, :undocked, :docked]
        unless valid.include? mode
          raise "expected '#{mode}' to be one of '#{valid}'"
        end

        hash = {:split => {:top => 'Merge',
                           :bottom => 'Dock and Merge'},
                :undocked => {:top => 'Dock',
                              :bottom => 'Split'},
                :docked => {:top => 'Undock',
                            :bottom => 'Split'}}
        mark = hash[mode][top_or_bottom]
        "label marked:'#{mark}'"
      end

      # @!visibility private
      # Returns a query for touching the iPad keyboard mode key.
      #
      # The mode key is also know as the 'Hide keyboard' key.
      #
      # @note
      #  This is only available when running outside of instruments.  Use
      #  ` _point_for_ipad_keyboard_mode_key` when the app is _not_ launched
      #  with instruments.
      #
      # raises an error when
      # * the device is not an iPad
      # * the app was launched with Instruments i.e. there is a <tt>run_loop</tt>
      def _query_for_keyboard_mode_key
        raise 'cannot detect keyboard mode key on iphone' if device_family_iphone?
        if uia_available?
          raise "UIA is available, use '_point_for_keyboard_mode_key' instead"
        end
        qstr = "view:'UIKBKeyView'"
        idx = query(qstr).count - 1
        "#{qstr} index:#{idx}"
      end

      # @!visibility private
      # Touches the bottom option on the popup dialog that is presented when the
      # the iPad keyboard `mode` key is touched and held.
      #
      # The `mode` key is also know as the 'Hide keyboard' key.
      #
      # The `mode` key allows the user to undock, dock, or split the keyboard.
      def _touch_bottom_keyboard_mode_row
        mode = ipad_keyboard_mode
        if uia_available?
          start_pt = _point_for_ipad_keyboard_mode_key
          # there are 10 pt btw the key and the popup and the row is 50 pt
          y_offset = 10 + 25
          end_pt = {:x => (start_pt[:x] - 40), :y => (start_pt[:y] - y_offset)}
          uia_pan_offset(start_pt, end_pt, {})
        else
          pan(_query_for_keyboard_mode_key, nil, {:duration => 1.0})
          touch(_query_for_touch_for_keyboard_mode_option(:bottom, mode))
          sleep(0.5)
        end
        2.times { sleep(0.5) }
      end

      # Touches the top option on the popup dialog that is presented when the
      # the iPad keyboard mode key is touched and held.
      #
      # The `mode` key is also know as the 'Hide keyboard' key.
      #
      # The `mode` key allows the user to undock, dock, or split the keyboard.
      def _touch_top_keyboard_mode_row
        mode = ipad_keyboard_mode
        if uia_available?
          start_pt = _point_for_ipad_keyboard_mode_key
          # there are 10 pt btw the key and the popup and each row is 50 pt
          # NB: no amount of offsetting seems to allow touching the top row
          #     when the keyboard is split

          x_offset = 40
          y_offset = 10 + 50 + 25
          end_pt = {:x => (start_pt[:x] - x_offset), :y => (start_pt[:y] - y_offset)}
          uia_pan_offset(start_pt, end_pt, {:duration => 1.0})
        else
          pan(_query_for_keyboard_mode_key, nil, {})
          touch(_query_for_touch_for_keyboard_mode_option(:top, mode))
          sleep(0.5)
        end
        2.times { sleep(0.5) }
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
        wait_for_keyboard()

        return if device_family_iphone?

        mode = ipad_keyboard_mode
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
        unless uia_available?
          screenshot_and_raise 'only available if there is a run_loop i.e. the app was launched with Instruments'
        end
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
        unless uia_available?
          screenshot_and_raise 'only available if there is a run_loop i.e. the app was launched with Instruments'
        end
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

    end
  end
end

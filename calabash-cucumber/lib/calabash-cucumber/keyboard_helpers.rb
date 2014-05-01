require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/playback_helpers'
require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber
    module KeyboardHelpers

      include Calabash::Cucumber::TestsHelpers
      include Calabash::Cucumber::Logging

      KEYPLANE_NAMES = {
          :small_letters => 'small-letters',
          :capital_letters => 'capital-letters',
          :numbers_and_punctuation => 'numbers-and-punctuation',
          :first_alternate => 'first-alternate',
          :numbers_and_punctuation_alternate => 'numbers-and-punctuation-alternate'
      }


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


      # returns a query string for detecting a keyboard
      def _qstr_for_keyboard
        "view:'UIKBKeyplaneView'"
      end

      # returns +true+ if a +docked+ keyboard is visible.
      #
      # a +docked+ keyboard is pinned to the bottom of the view.
      #
      # keyboards on the iPhone and iPod are +docked+.
      def docked_keyboard_visible?
        res = query(_qstr_for_keyboard).first
        return false if res.nil?

        return true if device_family_iphone?

        # ipad
        rect = res['rect']
        o = status_bar_orientation.to_sym
        case o
          when :left then
            rect['center_x'] == 592 and rect['center_y'] == 512
          when :right then
            rect['center_x'] == 176 and rect['center_y'] == 512
          when :up then
            rect['center_x'] == 384 and rect['center_y'] == 132
          when :down then
            rect['center_x'] == 384 and rect['center_y'] == 892
          else
            false
        end

      end

      # returns +true+ if an +undocked+ keyboard is visible.
      #
      # a +undocked+ keyboard is floats in the middle of the view
      #
      # returns +false+ if the device is not an iPad; all keyboards on the
      # iPhone and iPod are +docked+
      def undocked_keyboard_visible?
        return false if device_family_iphone?

        res = query(_qstr_for_keyboard).first
        return false if res.nil?

        not docked_keyboard_visible?
      end

      # returns +true+ if a +split+ keyboard is visible.
      #
      # a +split+ keyboard is floats in the middle of the view and is split to
      # allow faster thumb typing
      #
      # returns +false+ if the device is not an iPad; all keyboards on the
      # iPhone and iPod are +docked+
      def split_keyboard_visible?
        return false if device_family_iphone?
        query("view:'UIKBKeyView'").count > 0 and
              element_does_not_exist(_qstr_for_keyboard)
      end

      # returns true if there is a visible keyboard
      def keyboard_visible?
        docked_keyboard_visible? or undocked_keyboard_visible? or split_keyboard_visible?
      end

      # waits for a keyboard to appear and once it does appear waits for 0.3
      # seconds
      #
      # raises an error if no keyboard appears
      def wait_for_keyboard(opts={})
        default_opts = {:timeout_message => 'keyboard did not appear',
                        :post_timeout => 0.3}
        opts = default_opts.merge(opts)
        wait_for(opts) do
          keyboard_visible?
        end
      end

      # <b>DEPRECATED:</b> Use <tt>wait_for_keyboard</tt> instead.
      def await_keyboard
        _deprecated('0.9.163', "use 'wait_for_keyboard' instead", :warn)
        wait_for_keyboard
      end

      # returns an array of possible ipad keyboard modes
      def _ipad_keyboard_modes
        [:docked, :undocked, :split]
      end

      # returns the keyboard +mode+
      #
      #                   keyboard is pinned to bottom of the view #=> :docked
      #             keyboard is floating in the middle of the view #=> :undocked
      #                             keyboard is floating and split #=> :split
      #   no keyboard and :raise_on_no_visible_keyboard == +false+ #=> :unknown
      #
      # raises an error if the device is not an iPad
      #
      # raises an error if the <tt>:raise_on_no_visible_keyboard</tt> is +true+
      # (default) and no keyboard is visible
      #
      # set <tt>:raise_on_no_visible_keyboard</tt> to +false+ to use in +wait+
      # functions
      def ipad_keyboard_mode(opts = {})
        raise 'the keyboard mode does not exist on the iphone or ipod' if device_family_iphone?

        default_opts = {:raise_on_no_visible_keyboard => true}
        opts = default_opts.merge(opts)
        if opts[:raise_on_no_visible_keyboard]
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

      # ensures that there is a keyboard to enter text
      #
      # IMPORTANT will always raise an error when the keyboard is split and
      # there is no <tt>run_loop</tt> i.e. +UIAutomation+ is not available
      #
      # the default options are
      #   :screenshot +true+ raise with a screenshot
      #   :skip +false+ skip any checking (a nop) - used when iterating over
      #   keyplanes for keys
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

      # use keyboard to enter +chr+
      #
      # IMPORTANT: use the <tt>POST_ENTER_KEYBOARD</tt> environmental variable
      # to slow down the typing; adds a wait after each character is touched.
      # this can fix problems where the typing is too fast and characters are
      # skipped.
      #
      # there are several special 'characters', some of which do not appear on all
      # keyboards:
      # * 'Delete'
      # * 'Return'
      #
      # raises error if there is no visible keyboard or the keyboard is not
      # supported
      #
      # use the +should_screenshot+ to control whether or not to raise an error
      # if +chr+ is not found
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
            uia_type_string chr
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
            elsif code.eql?(UIA_SUPPORTED_CHARS['Return'])
              tap_keyboard_action_key
            else
              uia_type_string(code, '')
            end
          end
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

      # uses the keyboard to enter +text+
      #
      # raises an error if the text cannot be entered
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

      # touches the keyboard +action+ key
      #
      # the +action+ key depends on the keyboard.  some examples include:
      # * Return
      # * Next
      # * Go
      # * Join
      # * Search
      #
      # not all keyboards have an +action+ key
      # raises an error if the key cannot be entered
      def tap_keyboard_action_key
        if uia_available?
          uia_type_string '\n', '', false
        else
          keyboard_enter_char 'Return'
        end
      end

      # touches the keyboard +action+ key
      #
      # the +action+ key depends on the keyboard.
      #
      # some examples include:
      # * Return
      # * Next
      # * Go
      # * Join
      # * Search
      #
      # not all keyboards have an +action+ key
      # raises an error if the key cannot be entered
      def done
        tap_keyboard_action_key
      end

      # returns the current keyplane
      def _current_keyplane
        kp_arr = _do_keyplane(
            lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'componentName') },
            lambda { query("view:'UIKBKeyplaneView'", 'keyplane', 'name') })
        kp_arr.first.downcase
      end

      # searches the available keyplanes for +chr+ and if it is found, types it
      #
      # this is a recursive function
      #
      # IMPORTANT: use the <tt>KEYPLANE_SEARCH_STEP_PAUSE</tt> variable to
      # control how quickly the next keyplane is searched.  increase this value
      # if you encounter problems with missed keystrokes.
      #
      # raises an error if the +chr+ cannot be found
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

      # process a keyplane
      #
      # raises an error if there is not visible keyplane
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

      # returns a query string for finding the iPad 'Hide keyboard' button
      def _query_uia_hide_keyboard_button
        "uia.keyboard().buttons()['Hide keyboard']"
      end

      # dismisses a iPad keyboard by touching the 'Hide keyboard' button and waits
      # for the keyboard to disappear
      #
      # raises an error if the device is not an iPad.  the dismiss keyboard
      # key does not exist on the iPhone or iPod
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

      # returns the activation point of the iPad keyboard +mode+ key.
      #
      # the +mode+ key is also known as the <tt>Hide keyboard</tt> key.
      #
      # raises an error when
      # * the device is not an iPad
      # * the app was not launched with instruments i.e. there is no <tt>run_loop</tt>
      def _point_for_ipad_keyboard_mode_key
        raise 'the keyboard mode does not exist on the on the iphone' if device_family_iphone?
        raise 'cannot detect keyboard mode key without launching with instruments' unless uia_available?
        res = send_uia_command({:command => "#{_query_uia_hide_keyboard_button}.rect()"})
        origin = res['value']['origin']
        {:x => origin['x'], :y => origin['y']}

        # this did not work.
        #size = res['value']['size']
        #{:x => (origin['x'] + (size['width']/2)), :y => (origin['y'] + (size['height']/2))}
      end


      # returns a query string for touching one of the options that appears when
      # the iPad +mode+ key is touched and held.
      #
      # the +mode+ key is also know as the <tt>Hide keyboard</tt> key.
      #
      # valid arguments are:
      #   top_or_bottom :top | :bottom
      #   mode :docked | :undocked | :skipped
      #
      # use <tt>_point_for_keyboard_mode_key</tt> if there is a <tt>run_loop</tt>
      # available
      #
      # raises an error when
      # * the device is not an iPad
      # * the app was launched with Instruments i.e. there is a <tt>run_loop</tt>
      # * it is passed invalid arguments
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

      # returns a query for touching the iPad keyboard +mode+ key.
      #
      # the +mode+ key is also know as the <tt>Hide keyboard</tt> key.
      #
      # use <tt>_point_for_keyboard_mode_key</tt> if there is a <tt>run_loop</tt>
      # available
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

      # touches the bottom option on the popup dialog that is presented when the
      # the iPad keyboard +mode+ key is touched and held.
      #
      # the +mode+ key is also know as the <tt>Hide keyboard</tt> key.
      #
      # the +mode+ key allows the user to undock, dock, or split the keyboard.
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

      # touches the top option on the popup dialog that is presented when the
      # the iPad keyboard +mode+ key is touched and held.
      #
      # the +mode+ key is also know as the <tt>Hide keyboard</tt> key.
      #
      # the +mode+ key allows the user to undock, dock, or split the keyboard.
      def _touch_top_keyboard_mode_row
        mode = ipad_keyboard_mode
        if uia_available?
          start_pt = _point_for_ipad_keyboard_mode_key
          # there are 10 pt btw the key and the popup and each row is 50 pt
          # NB: no amount of offsetting seems to allow touching the top row
          #     when the keyboard is split
          y_offset = 10 + 50 + 25
          end_pt = {:x => (start_pt[:x] - 40), :y => (start_pt[:y] - y_offset)}
          uia_pan_offset(start_pt, end_pt, {:duration => 1.0})
        else
          pan(_query_for_keyboard_mode_key, nil, {})
          touch(_query_for_touch_for_keyboard_mode_option(:top, mode))
          sleep(0.5)
        end
        2.times { sleep(0.5) }
      end

      # ensures that the iPad keyboard is +docked+
      #
      # +docked+ means the keyboard is pinned to bottom of the view
      #
      # if the device is not an iPad, this is behaves like a call to
      # <tt>wait_for_keyboard</tt>
      #
      # raises an error when
      # * there is no visible keyboard or
      # * the +docked+ keyboard cannot be achieved
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


      # ensures that the iPad keyboard is +undocked+
      #
      # +undocked+ means the keyboard is floating in the middle of the view
      #
      # if the device is not an iPad, this is behaves like a call to
      # <tt>wait_for_keyboard</tt>
      #
      # raises an error when
      # * there is no visible keyboard or
      # * the an +undocked+ keyboard cannot be achieved
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


      # ensures that the iPad keyboard is +split+
      #
      # +split+ means the keyboard is floating in the middle of the view and is
      # split into two sections to enable faster thumb typing.
      #
      # if the device is not an iPad, this is behaves like a call to
      # <tt>wait_for_keyboard</tt>
      #
      # raises an error when
      # * there is no visible keyboard or
      # * the an +undocked+ keyboard cannot be achieved
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

      # used for detecting keyboards that are not normally visible to calabash
      # e.g. the keyboard on +'z'+
      #
      # IMPORTANT this should only be used when the app does not respond to
      # <tt>keyboard_visible?</tt>
      #
      # raises an error if the there is no <tt>run_loop</tt>
      def uia_keyboard_visible?
        unless uia_available?
          screenshot_and_raise 'only available if there is a run_loop i.e. the app was launched with Instruments'
        end
        res = uia_query_windows(:keyboard)
        not res.eql?(':nil')
      end

      # waits for a keyboard that is not normally visible to calabash
      # e.g. the keyboard on +MFMailComposeViewController+
      #
      # IMPORTANT this should only be used when the app does not respond to
      # <tt>keyboard_visible?</tt>
      #
      # raises an error if the there is no <tt>run_loop</tt>
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


      private

      # returns the the text in the first responder
      #
      # the first responder will be the +UITextField+ or +UITextView+ instance
      # that is associated with the visible keyboard.
      #
      # returns +empty string+ if no +textField+ or +textView+ elements are found to be
      # the first responder.
      #
      # raises an exception if there is no visible keyboard
      def _text_from_first_responder
        raise 'there must be a visible keyboard' unless keyboard_visible?

        ['textField', 'textView'].each do |ui_class|
          res = query("#{ui_class} isFirstResponder:1", :text)
          return res.first unless res.empty?
        end
        #noinspection RubyUnnecessaryReturnStatement
        return ""
      end

    end
  end
end

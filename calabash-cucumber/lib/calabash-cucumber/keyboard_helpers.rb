require 'calabash-cucumber/tests_helpers'

module Calabash
  module Cucumber
    module KeyboardHelpers
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers

      KEYPLANE_NAMES = {
          :small_letters => "small-letters",
          :capital_letters => "capital-letters",
          :numbers_and_punctuation => "numbers-and-punctuation",
          :first_alternate => "first-alternate",
          :numbers_and_punctuation_alternate => "numbers-and-punctuation-alternate"
      }


      IOS7_SUPPORTED_CHARS = {
          'Dictation' => nil,
          'Shift' => nil,
          'Delete' => '\b',
          'International' => nil,
          'More' => nil,
          'Return' => '\n'
      }
      #Possible values
      # 'Dictation'
      # 'Shift'
      # 'Delete'
      # 'International'
      # 'More'
      # 'Return'
      def keyboard_enter_char(chr, should_screenshot=true)
        #map(nil, :keyboard, load_playback_data("touch_done"), chr)
        if ios7?
          if chr.length == 1
            uia_type_string chr
          else
            code = IOS7_SUPPORTED_CHARS[chr]
            if code
              uia_type_string code
            else
              raise "Char #{chr} is not yet supported in iOS7"
            end
          end
          res = {'results' => []}
        else
          res = http({:method => :post, :path => 'keyboard'},
                     {:key => chr, :events => load_playback_data("touch_done")})
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
        res['results']
      end

      def done
        if ios7?
          uia_type_string '\n'
        else
          keyboard_enter_char "Return"
        end

      end


      def current_keyplane
        kp_arr = _do_keyplane(
            lambda { query("view:'UIKBKeyplaneView'", "keyplane", "componentName") },
            lambda { query("view:'UIKBKeyplaneView'", "keyplane", "name") })
        kp_arr.first.downcase
      end

      def search_keyplanes_and_enter_char(chr, visited=Set.new)
        cur_kp = current_keyplane
        begin
          keyboard_enter_char(chr, false)
          return true #found
        rescue
          visited.add(cur_kp)

          #figure out keyplane alternates
          props = _do_keyplane(
              lambda { query("view:'UIKBKeyplaneView'", "keyplane", "properties") },
              lambda { query("view:'UIKBKeyplaneView'", "keyplane", "attributes", "dict") }
          ).first

          known = KEYPLANE_NAMES.values

          found = false
          ["shift", "more"].each do |key|
            plane = props["#{key}-alternate"]
            if (known.member?(plane) and
                not visited.member?(plane))
              keyboard_enter_char(key.capitalize, false)
              found = search_keyplanes_and_enter_char(chr, visited)
              return true if found
              #not found => go back
              keyboard_enter_char(key.capitalize, false)
            end
          end
          return false
        end
      end

      def await_keyboard
        wait_for_elements_exist(["view:'UIKBKeyplaneView'"])
        sleep(0.3)
      end

      def keyboard_enter_text(text)
        fail("No visible keyboard") if element_does_not_exist("view:'UIKBKeyplaneView'")
        if ios7?
          uia_type_string(text)
        else
          text.each_char do |ch|
            begin
              keyboard_enter_char(ch, false)
            rescue
              search_keyplanes_and_enter_char(ch)
            end
          end
        end


      end


      def _do_keyplane(kbtree_proc, keyplane_proc)
        desc = query("view:'UIKBKeyplaneView'", "keyplane")
        fail("No keyplane (UIKBKeyplaneView keyplane)") if desc.empty?
        fail("Several keyplanes (UIKBKeyplaneView keyplane)") if desc.count > 1
        kp_desc = desc.first
        if /^<UIKBTree/.match(kp_desc)
          #ios5+
          kbtree_proc.call
        elsif /^<UIKBKeyplane/.match(kp_desc)
          #ios4
          keyplane_proc.call
        end
      end

    end
  end
end

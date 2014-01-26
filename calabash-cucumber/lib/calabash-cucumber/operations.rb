require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/keyboard_helpers'
require 'calabash-cucumber/wait_helpers'
require 'calabash-cucumber/launcher'
require 'net/http'
require 'test/unit/assertions'
require 'json'
require 'set'
require 'calabash-cucumber/version'
require 'calabash-cucumber/date_picker'


if not Object.const_defined?(:CALABASH_COUNT)
  #compatability with IRB
  CALABASH_COUNT = {:step_index => 0, :step_line => "irb"}
end


module Calabash
  module Cucumber
    module Operations
      include Test::Unit::Assertions
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers
      include Calabash::Cucumber::WaitHelpers
      include Calabash::Cucumber::KeyboardHelpers
      include Calabash::Cucumber::DatePicker

      def page(clz,*args)
        clz.new(self,*args)
      end

      def await_page(clz,*args)
        clz.new(self,*args).await
      end

      def home_direction
        status_bar_orientation.to_sym
      end

      def assert_home_direction(expected)
        unless expected.to_sym == home_direction
          screenshot_and_raise "Expected home button to have direction #{expected} but had #{home_direction}"
        end
      end

      def label(uiquery)
        query(uiquery, :accessibilityLabel)
      end

      def identifier(uiquery)
        query(uiquery, :accessibilityIdentifier)
      end

      def simple_touch(label, *args)
        touch("view marked:'#{label}'", *args)
      end

      def tap(label, *args)
        simple_touch(label, *args)
      end

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


      def set_user_pref(key, val)
        res = http({:method => :post, :path => 'userprefs'},
                   {:key=> key, :value => val})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "set_user_pref #{key} = #{val} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results']
      end

      def user_pref(key)
        res = http({:method => :get, :raw => true, :path => 'userprefs'},
                   {:key=> key})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "get user_pref #{key} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results'].first
      end

      #def screencast_begin
      #   http({:method=>:post, :path=>'screencast'}, {:action => :start})
      #end
      #
      #def screencast_end(file_name)
      #  res = http({:method=>:post, :path=>'screencast'}, {:action => :stop})
      #  File.open(file_name,'wb') do |f|
      #      f.write res
      #  end
      #  file_name
      #end
    end
  end
end

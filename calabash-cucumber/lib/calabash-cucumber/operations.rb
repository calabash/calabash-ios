require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/keyboard_helpers'
require 'calabash-cucumber/wait_helpers'
require 'calabash-cucumber/location'
require 'calabash-cucumber/launcher'
require 'net/http'
require 'test/unit/assertions'
require 'json'
require 'set'
require 'calabash-cucumber/version'


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
      include Calabash::Cucumber::Location



      def page(clz,*args)
        clz.new(self,*args)
      end

      def await_page(clz,*args)
        clz.new(self,*args).await
      end

      def home_direction
        @current_rotation = @current_rotation || :down
      end

      def assert_home_direction(expected)
        unless expected.to_sym == home_direction
          screenshot_and_raise "Expected home button to have direction #{expected} but had #{home_direction}"
        end
      end

      def escape_quotes(str)
        str.gsub("'", "\\\\'")
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

      def set_text(uiquery, txt)
        unless ENV['CALABASH_NO_DEPRECATION'] == '1'
          warn "WARNING: set_text will be deprecated.\n  * to enter text using the native keyboard use 'keyboard_enter_text'\n  * to clear a text field or text view use 'clear_text'"
          warn 'https://github.com/calabash/calabash-ios/wiki/03.5-Calabash-iOS-Ruby-API'
        end
        text_fields_modified = map(uiquery, :setText, txt)
        screenshot_and_raise "could not find text field #{uiquery}" if text_fields_modified.empty?
        text_fields_modified
      end

      def clear_text(uiquery)
        views_modified = map(uiquery, :setText, '')
        screenshot_and_raise "could not find text field #{uiquery}" if views_modified.empty?
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


      #not officially supported yet
      #def change_slider_value_to(q, value)
      #  target = value.to_f
      #  if target < 0
      #    pending "value '#{value}' must be >= 0"
      #  end
      #  min_val = query(q, :minimumValue).first
      #  # will not work for min_val != 0
      #  if min_val != 0
      #    screenshot_and_raise "sliders with non-zero minimum values are not supported - slider '#{q}' has minimum value of '#{min_val}'"
      #  end
      #  max_val = query(q, :maximumValue).first
      #  if target > max_val
      #    screenshot_and_raise "cannot change slider '#{q}' to '#{value}' because the maximum allowed value is '#{max_val}'"
      #  end
      #
      #  val = query(q, :value).first
      #  # the x offset is from the middle of the slider.
      #  # ex.  slider from 0 to 5
      #  #      to touch 3, x must be 0
      #  #      to touch 0, x must be -2.5
      #  #      to touch 5, x must be 2.5
      #  width = query(q, :frame).first["width"] - 10
      #
      #  cur_x = -width/2.0 + val*width
      #  tgt_x = -width/2.0 + target*width
      #
      #  interpolate("slide", :start =>q, :end => q,
      #              :offset_end => {:x => tgt_x, :y => 1},
      #              :offset_start => {:x => cur_x, :y => -1})
      #  sleep(0.1)
      #
      #  val = query(q, :value).first
      #  cur_x = -width/2.0 + val*width
      #  tgt_x = -width/2.0 + target*width
      #
      #  interpolate("slide", :start =>q, :end => q,
      #              :offset_end => {:x => tgt_x, :y => 1},
      #              :offset_start => {:x => cur_x, :y => -1})
      #
      #
      #end


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

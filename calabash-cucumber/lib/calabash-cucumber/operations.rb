require 'calabash-cucumber/tests_helpers'
require 'calabash-cucumber/keyboard_helpers'
require 'calabash-cucumber/wait_helpers'
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
      include Calabash::Cucumber::WaitHelpers
      include Calabash::Cucumber::KeyboardHelpers
      include Calabash::Cucumber::TestsHelpers

      DATA_PATH = File.expand_path(File.dirname(__FILE__))

      def macro(txt)
        if self.respond_to? :step
          step(txt)
        else
          Then txt
        end
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

      def query(uiquery, *args)
        map(uiquery, :query, *args)
      end

      def label(uiquery)
        query(uiquery, :accessibilityLabel)
      end


      def touch(uiquery, options={})
        options[:query] = uiquery
        views_touched = playback("touch", options)
        unless uiquery.nil?
          screenshot_and_raise "could not find view to touch: '#{uiquery}', args: #{options}" if views_touched.empty?
        end
        views_touched
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
        text_fields_modified = map(uiquery, :setText, txt)
        screenshot_and_raise "could not find text field #{uiquery}" if text_fields_modified.empty?
        text_fields_modified
      end


      def swipe(dir, options={})
        dir = dir.to_sym
        @current_rotation = @current_rotation || :down
        if @current_rotation == :left
          case dir
            when :left then
              dir = :down
            when :right then
              dir = :up
            when :up then
              dir = :left
            when :down then
              dir = :right
            else
          end
        end
        if @current_rotation == :right
          case dir
            when :left then
              dir = :up
            when :right then
              dir = :down
            when :up then
              dir = :right
            when :down then
              dir = :left
            else
          end
        end
        if @current_rotation == :up
          case dir
            when :left then
              dir = :right
            when :right then
              dir = :left
            when :up then
              dir = :down
            when :down then
              dir = :up
            else
          end
        end
        playback("swipe_#{dir}", options)
      end

      def cell_swipe(options={})
        playback("cell_swipe", options)
      end

      def scroll(uiquery, direction)
        views_touched=map(uiquery, :scroll, direction)
        screenshot_and_raise "could not find view to scroll: '#{uiquery}', args: #{direction}" if views_touched.empty?
        views_touched
      end

      def scroll_to_row(uiquery, number)
        views_touched=map(uiquery, :scrollToRow, number)
        if views_touched.empty? or views_touched.member? "<VOID>"
          screenshot_and_raise "Unable to scroll: '#{uiquery}' to: #{number}"
        end
        views_touched
      end

      def pinch(in_out, options={})
        file = "pinch_in"
        if in_out.to_sym==:out
          file = "pinch_out"
        end
        playback(file, options)
      end

      def rotate(dir)
        @current_rotation = @current_rotation || :down
        rotate_cmd = nil
        case dir
          when :left then
            if @current_rotation == :down
              rotate_cmd = "left_home_down"
              @current_rotation = :right
            elsif @current_rotation == :right
              rotate_cmd = "left_home_right"
              @current_rotation = :up
            elsif @current_rotation == :left
              rotate_cmd = "left_home_left"
              @current_rotation = :down
            elsif @current_rotation == :up
              rotate_cmd = "left_home_up"
              @current_rotation = :left
            end
          when :right then
            if @current_rotation == :down
              rotate_cmd = "right_home_down"
              @current_rotation = :left
            elsif @current_rotation == :left
              rotate_cmd = "right_home_left"
              @current_rotation = :up
            elsif @current_rotation == :right
              rotate_cmd = "right_home_right"
              @current_rotation = :down
            elsif @current_rotation == :up
              rotate_cmd = "right_home_up"
              @current_rotation = :right
            end
        end

        if rotate_cmd.nil?
          screenshot_and_raise "Does not support rotating #{dir} when home button is pointing #{@current_rotation}"
        end
        playback("rotate_#{rotate_cmd}")
      end

      def background(secs)
        res = http({:method => :post, :path => 'background'}, {:duration => secs})
      end


      def element_does_not_exist(uiquery)
        query(uiquery).empty?
      end

      def element_exists(uiquery)
        not element_does_not_exist(query)
      end

      def view_with_mark_exists(expected_mark)
        element_exists("view marked:'#{expected_mark}'")
      end

      def check_element_exists(query)
        if not element_exists(query)
          screenshot_and_raise "No element found for query: #{query}"
        end
      end

      def check_element_does_not_exist(query)
        if element_exists(query)
          screenshot_and_raise "Expected no elements to match query: #{query}"
        end
      end

      def check_view_with_mark_exists(expected_mark)
        check_element_exists("view marked:'#{expected_mark}'")
      end

      def element_is_not_hidden(uiquery)
        matches = query(uiquery, 'isHidden')
        matches.delete(true)
        !matches.empty?
      end


      def load_playback_data(recording, options={})
        os = options["OS"] || ENV["OS"] || "ios5"
        device = options["DEVICE"] || ENV["DEVICE"] || "iphone"

        rec_dir = ENV['PLAYBACK_DIR'] || "#{Dir.pwd}/playback"
        if !recording.end_with? ".base64"
          recording = "#{recording}_#{os}_#{device}.base64"
        end
        data = nil
        if (File.exists?(recording))
          data = File.read(recording)
        elsif (File.exists?("features/#{recording}"))
          data = File.read("features/#{recording}")
        elsif (File.exists?("#{rec_dir}/#{recording}"))
          data = File.read("#{rec_dir}/#{recording}")
        elsif (File.exists?("#{DATA_PATH}/resources/#{recording}"))
          data = File.read("#{DATA_PATH}/resources/#{recording}")
        else
          screenshot_and_raise "Playback not found: #{recording} (searched for #{recording} in #{Dir.pwd}, #{rec_dir}, #{DATA_PATH}/resources"
        end
        data
      end

      def playback(recording, options={})
        data = load_playback_data(recording)

        post_data = %Q|{"events":"#{data}"|
        post_data<< %Q|,"query":"#{escape_quotes(options[:query])}"| if options[:query]
        post_data<< %Q|,"offset":#{options[:offset].to_json}| if options[:offset]
        post_data<< %Q|,"reverse":#{options[:reverse]}| if options[:reverse]
        post_data<< %Q|,"prototype":"#{options[:prototype]}"| if options[:prototype]
        post_data << "}"

        res = http({:method => :post, :raw => true, :path => 'play'}, post_data)

        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "playback failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def interpolate(recording, options={})
        data = load_playback_data(recording)

        post_data = %Q|{"events":"#{data}"|
        post_data<< %Q|,"start":"#{escape_quotes(options[:start])}"| if options[:start]
        post_data<< %Q|,"end":"#{escape_quotes(options[:end])}"| if options[:end]
        post_data<< %Q|,"offset_start":#{options[:offset_start].to_json}| if options[:offset_start]
        post_data<< %Q|,"offset_end":#{options[:offset_end].to_json}| if options[:offset_end]
        post_data << "}"

        res = http({:method => :post, :raw => true, :path => 'interpolate'}, post_data)

        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "interpolate failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def record_begin
        http({:method => :post, :path => 'record'}, {:action => :start})
      end

      def record_end(file_name)
        res = http({:method => :post, :path => 'record'}, {:action => :stop})
        File.open("_recording.plist", 'wb') do |f|
          f.write res
        end
        device = ENV['DEVICE'] || 'iphone'
        os = ENV['OS'] || 'ios5'

        file_name = "#{file_name}_#{os}_#{device}.base64"
        system("/usr/bin/plutil -convert binary1 -o _recording_binary.plist _recording.plist")
        system("openssl base64 -in _recording_binary.plist -out #{file_name}")
        system("rm _recording.plist _recording_binary.plist")
        file_name
      end

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

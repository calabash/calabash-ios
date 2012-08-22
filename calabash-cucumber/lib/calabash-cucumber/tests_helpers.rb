require 'calabash-cucumber/core'

module Calabash
  module Cucumber
    module TestsHelpers
      include Calabash::Cucumber::Core

      def element_does_not_exist(uiquery)
        query(uiquery).empty?
      end

      def element_exists(uiquery)
        not element_does_not_exist(uiquery)
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

      def screenshot_and_raise(msg, prefix=nil, name=nil)
        screenshot(prefix, name)
        raise(msg)
      end

      def fail(msg="Error. Check log for details.", prefix=nil, name=nil)
        screenshot_and_raise(msg, prefix, name)
      end

      def screenshot(prefix=nil, name=nil)
        @screenshot_count ||= 0
        res = http({:method => :get, :path => 'screenshot'})
        prefix = prefix || ENV['SCREENSHOT_PATH'] || ""
        if name.nil?
          name = "screenshot"
        else
          if File.extname(name).downcase == ".png"
            name = name.split(".png")[0]
          end
        end

        path = "#{prefix}#{name}_#{@screenshot_count}.png"
        File.open(path, 'wb') do |f|
          f.write res
        end
        @screenshot_count += 1
        path
      end

    end
  end
end

require 'calabash-cucumber/launcher'
require 'calabash-cucumber/uia'


module Calabash
  module Cucumber
    module IOS7Operations
      include Calabash::Cucumber::UIA

      def ios7?
        launcher = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        ENV['OS']=='ios7' || (launcher && launcher.device && launcher.device.ios7?)
      end

      def touch_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_tap_offset(offset)
        else
          el_to_touch = find_or_raise(ui_query)
          rect = el_to_touch['rect']
          normalize_rect_for_orientation(rect)
          touch(el_to_touch, options)
          [el_to_touch]
        end
      end

      def normalize_rect_for_orientation(rect)
        orientation = device_orientation(true).to_sym
        launcher = Calabash::Cucumber::Launcher.launcher
        screen_size = launcher.device.screen_size
        case orientation
          when :right
            cx = rect['center_x']
            rect['center_x'] = rect['center_y']
            rect['center_y'] = screen_size[:width] - cx
          when :left
            cx = rect['center_x']
            rect['center_x'] = screen_size[:height] - rect['center_y']
            rect['center_y'] = cx
          when :up
            cy = rect['center_y']
            cx = rect['center_x']
            rect['center_y'] = screen_size[:height] - cy
            rect['center_x'] = screen_size[:width]  - cx
          else
            # no-op by design.
        end
      end

      def swipe_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_swipe_offset(offset, options)
        else
          el_to_swipe = find_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_swipe_offset(offset, options)
          [el_to_swipe]
        end
      end

      def pinch_ios7(in_or_out, options)
        ui_query = options[:query]
        offset =  options[:offset]
        duration = options[:duration] || 0.5
        if ui_query.nil?
          uia_pinch_offset(in_or_out, offset, {:duration => options[:duration]})
        else
          el_to_pinch = find_or_raise(ui_query)
          offset = point_from(el_to_pinch, options)
          uia_pinch_offset(in_or_out, offset, duration)
          [el_to_pinch]
        end
      end

      def pan_ios7(from, to, options={})
        from_result = find_or_raise from
        to_result = find_or_raise to
        uia_pan_offset(point_from(from_result, options), point_from(to_result, options), options)
        [to_result]
      end

      def find_or_raise(ui_query)
        results = query(ui_query)
        if results.empty?
          screenshot_and_raise "Unable to find element matching query #{ui_query}"
        else
          results.first
        end
      end

    end
  end
end

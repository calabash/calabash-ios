module Calabash
  module Cucumber
    # @!visibility private
    module Gestures

      require "calabash-cucumber/gestures/performer"

      # @!visibility private
      class Instruments < Calabash::Cucumber::Gestures::Performer

        require "calabash-cucumber/uia"
        include Calabash::Cucumber::UIA

        require "calabash-cucumber/connection_helpers"
        include Calabash::Cucumber::ConnectionHelpers

        require "calabash-cucumber/query_helpers"
        include Calabash::Cucumber::QueryHelpers

        require "calabash-cucumber/map"

        # @!visibility private
        UIA_STRATEGIES = [:preferences, :host, :shared_element]

        # @!visibility private
        def self.name
          :instruments
        end

        attr_reader :run_loop

        # @!visibility private
        def self.expect_valid_init_args(args)
          if args.nil?
            raise(ArgumentError, "Expected non-nil argument for initializer")
          end

          if !args.is_a?(Array)
            raise(ArgumentError, "Expected an array argument for initializer")
          end

          run_loop = args[0]

          if run_loop.nil?
            raise(ArgumentError,
%Q[Expected first element of args to be non-nil:

args = #{args}

])
          end

          if args.count != 1
            raise(ArgumentError,
%Q[Expected args to have exactly one element but found:

args = #{args}
])
          end

          self.expect_valid_run_loop(run_loop)
        end

        # @!visibility private
        def self.expect_valid_run_loop(run_loop)
          if run_loop.nil?
            raise(ArgumentError, "Expected run_loop arg to be non-nil")
          end

          if !run_loop.is_a?(Hash)
            raise(ArgumentError, %Q[
Expected run_loop arg to be a hash, but found:

run_loop = #{run_loop} is_a => #{run_loop.class}
])
          end

          if run_loop[:gesture_performer] != :instruments
            raise(ArgumentError, %Q[
Invalid :gesture_performer. Expected :instruments but found:

#{run_loop[:gesture_performer]}

in

#{run_loop}
])
          end

          [:pid, :udid, :index, :log_file, :uia_strategy].each do |key|
            if !run_loop[key]
              raise(ArgumentError, %Q[
Expected run_loop to have a truthy value for :#{key} but found:

#{run_loop}

])
            end
          end

          strategy = run_loop[:uia_strategy]
          if !self.valid_uia_strategy?(strategy)
             raise(ArgumentError, %Q[
Expected '#{strategy}' to be one of these supported strategies:

#{UIA_STRATEGIES}

])
          end
          true
        end

        # @!visibility private
        def self.valid_uia_strategy?(strategy)
         UIA_STRATEGIES.include?(strategy)
        end

        # @!visibility private
        def initialize(*args)
          Instruments.expect_valid_init_args(args)
          @run_loop = args[0]
        end

        # @!visibility private
        def touch(options)
          query_action(options, :uia_tap_offset)
        end

        # @!visibility private
        def double_tap(options)
          query_action(options, :uia_double_tap_offset)
        end

        # @!visibility private
        def two_finger_tap(options)
          query_action(options, :uia_two_finger_tap_offset)
        end

        # @!visibility private
        def flick(options)
          query_action(options) do |offset|
            delta = {:offset => options[:delta] || {}}
            uia_flick_offset(offset, point_from(offset, delta))
          end
        end

        # @!visibility private
        def touch_hold(options)
          query_action(options) do |offset|
            duration = options[:duration] || 3
            uia_touch_hold_offset(duration, offset)
          end
        end

        # @!visibility private
        def swipe(dir, options={})
          options = options.merge(:direction => dir)
          query_action(options, :uia_swipe_offset, options)
        end

        # @!visibility private
        def pan(from, to, options={})
          query_action(:query => from) do |from_offset|
            query_action(:query => to) do |to_offset|
              uia_pan_offset(from_offset, to_offset, options)
            end
          end
        end

        # @!visibility private
        def pinch(in_out, options)
          query_action(options) do |offset|
            options[:duration] = options[:duration] || 0.5
            uia_pinch_offset(in_out, offset, options)
          end
        end

        # @!visibility private
        def send_app_to_background(secs)
          uia_send_app_to_background(secs)
        end

        private

        # @!visibility private
        # Data interface
        # options[:query] or options[:offset]
        def query_action(options, action=nil, *args, &block)
          ui_query = options[:query]
          offset = options[:offset]
          if ui_query
            res = find_and_normalize(ui_query)
            return res if res.empty?
            el = res.first
            final_offset = point_from(el, options)
            if block_given?
              yield final_offset
            else
              self.send(action, final_offset, *args)
            end
            [el]
          else
            ##implies offset
            if block_given?
              yield offset
            else
              self.send(action, offset, *args)
            end
          end
        end

        # @!visibility private
        def find_and_normalize(ui_query)
          raw_result = Calabash::Cucumber::Map.raw_map(ui_query, :query)
          orientation = raw_result["status_bar_orientation"]
          res = raw_result["results"]

          return res if res.empty?

          first_res = res.first
          normalize_rect_for_orientation!(orientation, first_res["rect"]) if first_res["rect"]

          res
        end

        # @!visibility private
        def normalize_rect_for_orientation!(orientation, rect)
          orientation = orientation.to_sym
          launcher = Calabash::Cucumber::Launcher.launcher
          device = launcher.device

          # Coordinate translations for orientation is handled in the server for iOS 8+
          if device.ios_major_version.to_i >= 8
            return
          end

          # We cannot use Device#screen_dimensions here because on iPads the height
          # and width are the opposite of what we expect.
          # @todo Move all coordinate/orientation translation into the server.
          if device.ipad?
            screen_size = { :width => 768, :height => 1024 }
          elsif device.iphone_4in?
            screen_size = { :width => 320, :height => 568 }
          else
            screen_size = { :width => 320, :height => 480 }
          end

          case orientation
            when :right
              cx = rect["center_x"]
              rect["center_x"] = rect["center_y"]
              rect["center_y"] = screen_size[:width] - cx
            when :left
              cx = rect["center_x"]
              rect["center_x"] = screen_size[:height] - rect["center_y"]
              rect["center_y"] = cx
            when :up
              cy = rect["center_y"]
              cx = rect["center_x"]
              rect["center_y"] = screen_size[:height] - cy
              rect["center_x"] = screen_size[:width] - cx
            else
              # no-op by design.
          end
        end
      end
    end
  end
end

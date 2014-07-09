require 'calabash-cucumber/launcher'
require 'calabash-cucumber/uia'
require 'calabash-cucumber/actions/instruments_actions'
require 'calabash-cucumber/actions/playback_actions'
require 'calabash-cucumber/environment_helpers'

module Calabash
  module Cucumber
    module IOS7Operations
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::EnvironmentHelpers

      # todo deprecate the Calabash::Cucumber::IOS7Operations


      # <b>DEPRECATED</b>
      #
      # abstracted into <tt>actions/instruments_actions.rb</tt> - actions that
      # can be performed under instruments
      # @!visibility private
      def touch_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_tap_offset(offset)
        else
          el_to_touch = find_and_normalize_or_raise(ui_query)
          touch(el_to_touch, options)
          [el_to_touch]
        end
      end

      # @!visibility private
      def swipe_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_swipe_offset(offset, options)
        else
          el_to_swipe = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_swipe_offset(offset, options)
          [el_to_swipe]
        end
      end

      # @!visibility private
      def pinch_ios7(in_or_out, options)
        ui_query = options[:query]
        offset =  options[:offset]
        duration = options[:duration] || 0.5
        if ui_query.nil?
          uia_pinch_offset(in_or_out, offset, {:duration => options[:duration]})
        else
          el_to_pinch = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_pinch, options)
          uia_pinch_offset(in_or_out, offset, duration)
          [el_to_pinch]
        end
      end

      # @!visibility private
      def pan_ios7(from, to, options={})
        from_result = find_and_normalize_or_raise from
        to_result = find_and_normalize_or_raise to
        uia_pan_offset(point_from(from_result, options),
                       point_from(to_result, options),
                       options)
        [to_result]
      end

      # @!visibility private
      def double_tap_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_double_tap_offset(offset)
        else
          el_to_swipe = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_double_tap_offset(offset)
          [el_to_swipe]
        end
      end

      # @!visibility private
      def two_finger_tap_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_two_finger_tap_offset(offset)
        else
          el_to_swipe = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_two_finger_tap_offset(offset)
          [el_to_swipe]
        end
      end

      # @!visibility private
      def flick_ios7(options, delta)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_flick_offset(offset, add_offset(offset, delta))
        else
          el_to_swipe = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_flick_offset(offset, add_offset(offset, delta))
          [el_to_swipe]
        end
      end

      # @!visibility private
      def touch_hold_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        duration = options[:duration] || 4
        if ui_query.nil?
          uia_touch_hold_offset(duration, offset)
        else
          el_to_swipe = find_and_normalize_or_raise(ui_query)
          offset = point_from(el_to_swipe, options)
          uia_touch_hold_offset(duration, offset)
          [el_to_swipe]
        end
      end
    end
  end
end

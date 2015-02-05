require 'calabash-cucumber/uia'
require 'calabash-cucumber/connection_helpers'
require 'calabash-cucumber/query_helpers'
require 'calabash-cucumber/map'

# @!visibility private
class Calabash::Cucumber::InstrumentsActions
  include Calabash::Cucumber::UIA
  include Calabash::Cucumber::ConnectionHelpers
  include Calabash::Cucumber::QueryHelpers
  include Calabash::Cucumber::Map

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
    raw_result = raw_map(ui_query, :query)
    orientation = raw_result['status_bar_orientation']
    res = raw_result['results']

    return res if res.empty?

    first_res = res.first
    normalize_rect_for_orientation!(orientation, first_res['rect']) if first_res['rect']

    res
  end

  # @!visibility private
  def normalize_rect_for_orientation!(orientation, rect)
    orientation = orientation.to_sym
    launcher = Calabash::Cucumber::Launcher.launcher

    # Coordinate translations for orientation is handled in the server for iOS 8+
    # https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICoordinateSpace_protocol/index.html
    if launcher.ios_major_version.to_i >= 8
      return
    end

    # We cannot use Device#screen_dimensions here because on iPads the height
    # and width are the opposite of what we expect.
    # @todo Move all coordinate/orientation translation into the server.
    device = launcher.device
    if device.ipad?
      screen_size = { :width => 768, :height => 1024 }
    elsif device.iphone_4in?
      screen_size = { :width => 320, :height => 568 }
    else
      screen_size = { :width => 320, :height => 480 }
    end

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
        rect['center_x'] = screen_size[:width] - cx
      else
        # no-op by design.
    end
  end
end

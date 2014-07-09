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

  def touch(options)
    query_action(options, :uia_tap_offset)
  end

  def wait_tap(options)
    uia_wait_tap(options[:query], options)
  end

  def double_tap(options)
    query_action(options, :uia_double_tap_offset)
  end

  def two_finger_tap(options)
    query_action(options, :uia_two_finger_tap_offset)
  end

  def flick(options)
    query_action(options) do |offset|
      delta = {:offset => options[:delta] || {}}
      uia_flick_offset(offset, point_from(offset, delta))
    end
  end


  def touch_hold(options)
    query_action(options) do |offset|
      duration = options[:duration] || 3
      uia_touch_hold_offset(duration, offset)
    end
  end

  def swipe(dir, options={})
    options = options.merge(:direction => dir)
    query_action(options, :uia_swipe_offset, options)
  end

  def pan(from, to, options={})
    query_action(:query => from) do |from_offset|
      query_action(:query => to) do |to_offset|
        uia_pan_offset(from_offset, to_offset, options)
      end
    end

  end

  def pinch(in_out, options)
    query_action(options) do |offset|
      options[:duration] = options[:duration] || 0.5
      uia_pinch_offset(in_out, offset, options)
    end
  end

  def send_app_to_background(secs)
    uia_send_app_to_background(secs)
  end

  private

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

  def find_and_normalize(ui_query)
    raw_result = raw_map(ui_query, :query)
    orientation = raw_result['status_bar_orientation']
    res = raw_result['results']

    return res if res.empty?

    first_res = res.first
    normalize_rect_for_orientation!(orientation, first_res['rect']) if first_res['rect']

    res
  end

  def normalize_rect_for_orientation!(orientation, rect)
    orientation = orientation.to_sym
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
        rect['center_x'] = screen_size[:width] - cx
      else
        # no-op by design.
    end
  end


end
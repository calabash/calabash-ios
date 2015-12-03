require 'calabash-cucumber/playback_helpers'
require 'calabash-cucumber/connection_helpers'
require 'calabash-cucumber/query_helpers'

# @!visibility private
class Calabash::Cucumber::PlaybackActions
  include Calabash::Cucumber::PlaybackHelpers
  include Calabash::Cucumber::ConnectionHelpers
  include Calabash::Cucumber::QueryHelpers

  # @!visibility private
  def touch(options)
    playback('touch', options)
  end

  # @!visibility private
  def double_tap(options)
    playback('double_tap', options)
  end

  # @!visibility private
  def two_finger_tap(*args)
    raise error_message('two_finger_tap')
  end

  # @!visibility private
  def flick(*args)
    raise error_message('flick')
  end

  # @!visibility private
  def touch_hold(options)
    playback('touch_hold', options)
  end

  # @!visibility private
  def swipe(dir, options={})
    current_orientation = options[:status_bar_orientation].to_sym
    if current_orientation == :left
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

    if current_orientation == :right
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

    if current_orientation == :up
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

  # @!visibility private
  def pan(from,to,options={})
    interpolate 'pan', options.merge(:start => from, :end => to)
  end

  # @!visibility private
  def pinch(in_out,options)
    file = "pinch_in"
    if in_out==:out
      file = "pinch_out"
    end
    playback(file, options)
  end

  # @!visibility private
  def send_app_to_background(secs)
    raise 'Not implemented when running without instruments / UIA'
  end

  private
  # @!visibility private
  def error_message(gesture)
    "Gesture: '#{gesture}' not supported unless running with instruments."
  end
end

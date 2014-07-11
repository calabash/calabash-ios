require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Provides methods for rotating a device in a direction or to a particular
    # orientation.
    module RotationHelpers

      include Calabash::Cucumber::Logging

      def rotation_candidates
        %w(rotate_left_home_down rotate_left_home_left rotate_left_home_right rotate_left_home_up
           rotate_right_home_down rotate_right_home_left rotate_right_home_right rotate_right_home_up)
      end

      # Rotates the home button position to the position indicated by `dir`.
      #
      # @example portrait
      #  rotate_home_button_to :down
      #
      # @example upside down
      #  rotate_home_button_to :up
      #
      # @example landscape with left home button AKA: _right_ landscape
      #  rotate_home_button_to :left
      #
      # @example landscape with right home button AKA: _left_ landscape
      #  rotate_home_button_to :right
      #
      # @note Refer to Apple's documentation for clarification about left vs.
      #  right landscape orientations.
      #
      # @note For legacy support the `dir` argument can be a String or Symbol.
      #  Please update your code to pass a Symbol.
      #
      # @note For legacy support `:top` and `top` are synonyms for `:up`.
      #  Please update your code to pass `:up`.
      #
      # @note For legacy support `:bottom` and `bottom` are synonyms for `:down`.
      #  Please update your code to pass `:down`.
      #
      # @note This method generates verbose messages when full console logging
      #  is enabled.  See {Calabash::Cucumber::Logging#full_console_logging?}.
      #
      # @param [Symbol] dir The position of the home button after the rotation.
      #  Can be one of `{:down | :left | :right | :up }`.
      #
      # @return [Symbol] The orientation of the button when all rotations have
      #  been completed.  If there is problem rotating, this method will return
      #  `:down` regardless of the actual home button position.
      #
      # @todo When running under UIAutomation, we should use that API to rotate
      #  instead of relying on playbacks.
      def rotate_home_button_to(dir)
        dir_sym = dir.to_sym
        if dir_sym.eql?(:top)
          if full_console_logging?
            calabash_warn "converting '#{dir}' to ':up' - please adjust your code"
          end
          dir_sym = :up
        end

        if dir_sym.eql?(:bottom)
          if full_console_logging?
            calabash_warn "converting '#{dir}' to ':down' - please adjust your code"
          end
          dir_sym = :down
        end

        directions = [:down, :up, :left, :right]
        unless directions.include?(dir_sym)
          screenshot_and_raise "expected one of '#{directions}' as an arg to 'rotate_home_button_to but found '#{dir}'"
        end

        res = status_bar_orientation()
        if res.nil?
          screenshot_and_raise "expected 'status_bar_orientation' to return a non-nil value"
        else
          res = res.to_sym
        end

        return res if res.eql? dir_sym

        rotation_candidates.each { |candidate|
          if full_console_logging?
            puts "try to rotate to '#{dir_sym}' using '#{candidate}'"
          end
          playback(candidate)
          # need a longer sleep for cloud testing
          sleep(0.4)

          res = status_bar_orientation
          if res.nil?
            screenshot_and_raise "expected 'status_bar_orientation' to return a non-nil value"
          else
            res = res.to_sym
          end

          return if res.eql? dir_sym
        }

        if full_console_logging?
          calabash_warn "Could not rotate home button to '#{dir}'."
          calabash_warn 'Is rotation enabled for this controller?'
          calabash_warn "Will return 'down'"
        end
        :down
      end

      # Rotates the device in the direction indicated by `dir`.
      #
      # @example rotate left
      #  rotate :left
      #
      # @example rotate right
      #  rotate :right
      #
      # @example rotate down
      #  rotate :down
      #
      # @example rotate up
      #  rotate :up
      #
      # @note For legacy support the `dir` argument can be a String or Symbol.
      #  Please update your code to pass a Symbol.
      #
      # @param [Symbol] dir The position of the home button after the rotation.
      #  Can be one of `{:down | :left | :right | :up }`.
      #
      # @todo When running under UIAutomation, we should use that API to rotate
      #  instead of relying on playbacks.
      def rotate(dir)
        dir = dir.to_sym
        current_orientation = status_bar_orientation().to_sym
        rotate_cmd = nil
        case dir
          when :left then
            if current_orientation == :down
              rotate_cmd = 'left_home_down'
            elsif current_orientation == :right
              rotate_cmd = 'left_home_right'
            elsif current_orientation == :left
              rotate_cmd = 'left_home_left'
            elsif current_orientation == :up
              rotate_cmd = 'left_home_up'
            end
          when :right then
            if current_orientation == :down
              rotate_cmd = 'right_home_down'
            elsif current_orientation == :left
              rotate_cmd = 'right_home_left'
            elsif current_orientation == :right
              rotate_cmd = 'right_home_right'
            elsif current_orientation == :up
              rotate_cmd = 'right_home_up'
            end
        end

        if rotate_cmd.nil?
          if full_console_logging?
            puts "Could not rotate device in direction '#{dir}' with orientation '#{current_orientation} - will do nothing"
          end
        else
          playback("rotate_#{rotate_cmd}")
        end
      end

    end
  end
end
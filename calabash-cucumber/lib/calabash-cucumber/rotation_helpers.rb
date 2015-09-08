require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Provides methods for rotating a device in a direction or to a particular
    # orientation.
    module RotationHelpers

      include Calabash::Cucumber::Logging

      # @!visibility private
      def rotation_candidates
        %w(rotate_left_home_down rotate_left_home_left rotate_left_home_right rotate_left_home_up
           rotate_right_home_down rotate_right_home_left rotate_right_home_right rotate_right_home_up)
      end

      # Rotates the home button to a position relative to the status bar.
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
      # @param [Symbol] direction The position of the home button after the rotation.
      #  Can be one of `{:down | :left | :right | :up }`.
      #
      # @note A rotation will only occur if your view controller and application
      #  support the target orientation.
      #
      # @return [Symbol] The position of the home button relative to the status
      #  bar when all rotations have been completed.
      def rotate_home_button_to(direction)

        begin
          as_symbol = ensure_valid_rotate_home_to_arg(direction)
        rescue ArgumentError => e
          raise ArgumentError, e.message
        end

        current_orientation = status_bar_orientation.to_sym

        return current_orientation if current_orientation == as_symbol

        if ios_version >= RunLoop::Version.new('9.0')
          rotate_to_uia_orientation(as_symbol)
          recalibrate_after_rotation
          status_bar_orientation.to_sym
        else
          rotate_home_button_to_position_with_playback(as_symbol)
        end
      end

      # Rotates the device in the direction indicated by `direction`.
      #
      # @example rotate left
      #  rotate :left
      #
      # @example rotate right
      #  rotate :right
      #
      # @param [Symbol] direction The direction to rotate. Can be :left or :right.
      #
      # @return [Symbol] The position of the home button relative to the status
      #   bar after the rotation.  Will be one of `{:down | :left | :right | :up }`.
      # @raise [ArgumentError] If direction is not :left or :right.
      def rotate(direction)

        as_symbol = direction.to_sym

        if as_symbol != :left && as_symbol != :right
          raise ArgumentError,
                "Expected '#{direction}' to be :left or :right"
        end

        current_orientation = status_bar_orientation.to_sym

        if ios_version >= RunLoop::Version.new('9.0')
          result = rotate_with_uia(as_symbol, current_orientation)
        else
          result = rotate_with_playback(as_symbol, current_orientation)
        end
        recalibrate_after_rotation

        ap result if debug_logging?

        status_bar_orientation
      end

      private

      def ensure_valid_rotate_home_to_arg(arg)
        coerced = arg.to_sym

        if coerced == :top
          coerced = :up
        elsif coerced == :bottom
          coerced = :down
        end

        allowed = [:down, :up, :left, :right]
        unless allowed.include?(coerced)
          raise ArgumentError,
                "Expected '#{arg}' to be :down, :up, :left, or :right"
        end
        coerced
      end

      UIA_DEVICE_ORIENTATION = {
            :portrait => 1,
            :upside_down => 2,
            :landscape_left => 3,
            :landscape_right => 4
      }.freeze

      def rotate_home_button_to_position_with_playback(home_button_position)

        rotation_candidates.each do |candidate|
          if debug_logging?
            calabash_info "Trying to rotate Home Button to '#{home_button_position}' using '#{candidate}'"
          end

          playback(candidate)
          sleep(0.4)
          recalibrate_after_rotation

          current_orientation = status_bar_orientation.to_sym
          if current_orientation == home_button_position
            return current_orientation
          end
        end

        if debug_logging?
          calabash_warn %Q{
Could not rotate Home Button to '#{home_button_position}'."
Is rotation enabled for this controller?}
        end
        :down
      end

      def rotate_to_uia_orientation(orientation)
        case orientation
          when :down then key = :portrait
          when :up then key = :upside_down
          when :left then key = :landscape_right
          when :right then key = :landscape_left
          else
            raise ArgumentError,
                  "Expected '#{orientation}' to be :left, :right, :up, or :down"
        end
        value = UIA_DEVICE_ORIENTATION[key]
        cmd = "UIATarget.localTarget().setDeviceOrientation(#{value})"
        uia(cmd)
      end

      def rotate_with_uia(direction, current_orientation)
        key = uia_orientation_key(direction, current_orientation)
        value = UIA_DEVICE_ORIENTATION[key]
        cmd = "UIATarget.localTarget().setDeviceOrientation(#{value})"
        uia(cmd)
      end

      def uia_orientation_key(direction, current_orientation)

        key = nil
        case direction
          when :left then
            if current_orientation == :down
              key = :landscape_right
            elsif current_orientation == :right
              key = :portrait
            elsif current_orientation == :left
              key = :upside_down
            elsif current_orientation == :up
              key = :landscape_left
            end
          when :right then
            if current_orientation == :down
              key = :landscape_left
            elsif current_orientation == :right
              key = :upside_down
            elsif current_orientation == :left
              key = :portrait
            elsif current_orientation == :up
              key = :landscape_right
            end
          else
            raise ArgumentError,
                  "Expected '#{direction}' to be :left or :right"
        end
        key
      end

      def recording_name(direction, current_orientation)
        recording_name = nil
        case direction
          when :left then
            if current_orientation == :down
              recording_name = 'left_home_down'
            elsif current_orientation == :right
              recording_name = 'left_home_right'
            elsif current_orientation == :left
              recording_name = 'left_home_left'
            elsif current_orientation == :up
              recording_name = 'left_home_up'
            end
          when :right then
            if current_orientation == :down
              recording_name = 'right_home_down'
            elsif current_orientation == :left
              recording_name = 'right_home_left'
            elsif current_orientation == :right
              recording_name = 'right_home_right'
            elsif current_orientation == :up
              recording_name = 'right_home_up'
            end
          else
            raise ArgumentError,
                  "Expected '#{direction}' to be 'left' or 'right'"
        end
        "rotate_#{recording_name}"
      end

      def rotate_with_playback(direction, current_orientation)
        name = recording_name(direction, current_orientation)

        if debug_logging?
          puts "Could not rotate device '#{direction}' given '#{current_orientation}'; nothing to do."
        end

        playback(name)
      end
    end
  end
end

module Calabash
  module Cucumber

    # Provides methods for rotating a device in a direction or to a particular
    # orientation.
    module RotationHelpers

      require "run_loop"

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

        rotate_to_uia_orientation(as_symbol)
        recalibrate_after_rotation
        status_bar_orientation.to_sym
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

        result = rotate_with_uia(as_symbol, current_orientation)

        recalibrate_after_rotation

        ap result if RunLoop::Environment.debug?

        status_bar_orientation
      end

      private

      # @! visibility private
      def recalibrate_after_rotation
        uia_query :window
      end

      # @! visibility private
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

      # @! visibility private
      UIA_DEVICE_ORIENTATION = {
            :portrait => 1,
            :upside_down => 2,
            :landscape_left => 3, # Home button on the right
            :landscape_right => 4 # Home button on the left
      }.freeze

      # @! visibility private
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

      # @! visibility private
      def rotate_with_uia(direction, current_orientation)
        key = orientation_key(direction, current_orientation)
        value = UIA_DEVICE_ORIENTATION[key]
        cmd = "UIATarget.localTarget().setDeviceOrientation(#{value})"
        uia(cmd)
      end

      # @! visibility private
      #
      # It is important to remember that the current orientation is the
      # position of the home button:
      #
      # :up => home button on the top => upside_down
      # :bottom => home button on the bottom => portrait
      # :left => home button on the left => landscape_right
      # :right => home button on the right => landscape_left
      #
      # Notice how :left and :right are mapped.
      def orientation_key(direction, current_orientation)
        key = nil
        case direction
          when :left then
            if current_orientation == :down
              key = :landscape_left
            elsif current_orientation == :right
              key = :upside_down
            elsif current_orientation == :left
              key = :portrait
            elsif current_orientation == :up
              key = :landscape_right
            end
          when :right then
            if current_orientation == :down
              key = :landscape_right
            elsif current_orientation == :right
              key = :portrait
            elsif current_orientation == :left
              key = :upside_down
            elsif current_orientation == :up
              key = :landscape_left
            end
          else
            raise ArgumentError,
                  "Expected '#{direction}' to be :left or :right"
        end
        key
      end
    end
  end
end

module Calabash
  module Cucumber

    # @!visibility private
    module RotationHelpers

      # @! visibility private
      def expect_valid_rotate_home_to_arg(arg)
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

      # @!visibility private
      def orientation_for_key(key)
        DEVICE_ORIENTATION[key]
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

      private

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
      # Notice how :left and :right are mapped to their logical opposite.
      # @!visibility private
      # @! visibility private
      DEVICE_ORIENTATION = {
        :portrait => 1,
        :upside_down => 2,
        :landscape_left => 3, # Home button on the right
        :landscape_right => 4 # Home button on the left
      }.freeze

    end
  end
end

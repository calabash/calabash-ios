require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Provides methods for rotating a device in a direction or to a particular
    # orientation.
    module RotationHelpers

      include Calabash::Cucumber::Logging

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
      # @param [Symbol] dir The position of the home button after the rotation.
      #  Can be one of `{:down | :left | :right | :up }`.
      def rotate_home_button_to(dir)
        uia_rotate_home_button_to(dir)
      end

      # Rotates the device in the direction indicated by `dir`.
      #
      # @example rotate left
      #  rotate :left
      #  same as rotate('counter-clockwise')
      #
      # @example rotate right
      #  rotate :right
      #  same as rotate('clockwise')
      #
      # @note The `dir` argument can be a String or Symbol.
      def rotate(dir)
        uia_rotate(dir)
      end
    end
  end
end
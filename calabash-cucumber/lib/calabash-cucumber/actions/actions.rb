module Calabash
  module Cucumber
    # noinspection RubyUnusedLocalVariable
    #
    # IMPORTANT:  Developers, do not require this file anywhere.  Do not extend or
    #            include this module in any other class or module.


    # This module provides methods for performing gestures like touching,
    # panning, and swiping.
    #
    # @note The methods defined here are _stubs_ for documentation purposes.
    #
    # @note Several of these methods are only available if you have launched
    #  with instruments.
    #
    # @note The terms _touch_ and _tap_ are used interchangeably in the documentation.
    module Actions

      # Performs the touch gesture.
      def touch(options)
        # stub for documentation
      end

      # Performs the touch gesture after wait for the touch target to appear.
      def wait_tap(options)
        # stub for documentation
      end

      # Performs the double tap gesture.
      def double_tap(options)
        # stub for documentation
      end

      # Performs the touch-and-hold gesture.
      def touch_hold(options)
        # stub for documentation
      end

      # Performs the swipe gesture.
      def swipe(dir, options={})
        # stub for documentation
      end

      # Performs the pan gesture.
      def pan(from, to, options={})
        # stub for documentation
      end

      # Performs the pinch gesture.
      def pinch(in_out, options)
        # stub for documentation
      end

      # uia only

      # Performs the two-finger-tap gesture.
      #
      # @note This method requires that your app be launched with instruments.
      #
      # @raise [RuntimeError] if the app has not been launched with instruments.
      def two_finger_tap(options)
        # stub for documentation
      end

      # Performs the flick gesture.
      #
      # @note This method requires that your app be launched with instruments.
      #
      # @raise [RuntimeError] if the app has not been launched with instruments.
      def flick(options)
        # stub for documentation
      end

      # Sends the app to the background, emulating the behavior of touching the
      # the Home button.
      #
      # @note This method requires that your app be launched with instruments.
      #
      # @raise [RuntimeError] if the app has not been launched with instruments.
      def send_app_to_background(secs)
        # stub for documentation
      end

    end
  end
end
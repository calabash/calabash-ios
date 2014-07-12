require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Contains methods for interacting with the status bar.
    module StatusBarHelpers

      include Calabash::Cucumber::Logging

      # Returns the device orientation as reported by `[[UIDevice currentDevice] orientation]`.
      #
      # @note This method is not used internally by the gem.  It is provided
      #  as an alternative to `status_bar_orientation`.  We recommend that you
      #  use `status_bar_orientation` whenever possible.
      #
      # @note Devices that are lying on a flat surface will report their
      #  orientation as 'face up' or 'face down'.  In order to translate
      #  gestures based on orientation, Calabash must have left, right, up, or
      #  down orientation. To that end, if a device is lying flat, this method
      #  will ***force*** a down orientation.  This will happen regardless of
      #  the value of the `force_down` optional argument.
      #
      # @see #status_bar_orientation
      # @see Calabash::Cucumber::RotationHelpers#rotate_home_button_to
      #
      # @param [Boolean] force_down if true, do rotations until a down
      #  orientation is achieved
      # @return [Symbol] Returns the device orientation as one of
      #  `{:down, :up, :left, :right}`.
      def device_orientation(force_down=false)
        res = map(nil, :orientation, :device).first

        if ['face up', 'face down'].include?(res)
          if full_console_logging?
            if force_down
              puts "WARN  found orientation '#{res}' - will rotate to force orientation to 'down'"
            end
          end

          return res unless force_down
          return rotate_home_button_to :down
        end

        return res unless res.eql?('unknown')
        return res unless force_down
        rotate_home_button_to(:down)
      end

      # Returns the home button position relative to the status bar.
      #
      # @note You should always prefer to use this method over
      #  `device_orientation`.
      #
      # @note This method works even if a status bar is not visible.
      #
      # @return [String] Returns the device orientation as one of
      #  `{'down' | 'up' | 'left' | 'right'}`.
      def status_bar_orientation
        map(nil, :orientation, :status_bar).first
      end

      # Is the device in the portrait orientation?
      #
      # @return [Boolean] Returns true if the device is in the 'up' or 'down'
      #  orientation.
      def portrait?
        o = status_bar_orientation
        o.eql?('up') or o.eql?('down')
      end

      # Is the device in the landscape orientation?
      #
      # @return [Boolean] Returns true if the device is in the 'left' or 'right'
      #  orientation.
      def landscape?
        o = status_bar_orientation
        o.eql?('right') or o.eql?('left')
      end

    end
  end
end
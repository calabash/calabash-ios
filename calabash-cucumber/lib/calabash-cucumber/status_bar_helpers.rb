module Calabash
  module Cucumber

    # Contains methods for interacting with the status bar.
    module StatusBarHelpers

      require "calabash-cucumber/map"

      require "calabash-cucumber/connection_helpers"
      include Calabash::Cucumber::ConnectionHelpers

      # Returns the device orientation as reported by
      # `[[UIDevice currentDevice] orientation]`.
      #
      # @note This method is not used internally by the gem.  It is provided
      #  as an alternative to `status_bar_orientation`.  We recommend that you
      #  use `status_bar_orientation` whenever possible.
      #
      # @note Devices that are lying on a flat surface will report their
      #  orientation as 'face up' or 'face down'.
      #
      # @see #status_bar_orientation
      # @see Calabash::Cucumber::RotationHelpers#rotate_home_button_to
      #
      # @return [Symbol] Returns the device orientation as one of
      #  `{'down', 'up', 'left', 'right', 'face up', 'face down', 'unknown'}`.
      def device_orientation
        Map.map(nil, :orientation, :device).first
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
        Map.map(nil, :orientation, :status_bar).first
      end

      # Returns details about the status bar like the frame, its visibility,
      # and orientation.
      #
      # Requires calabash server 0.20.0.
      def status_bar_details
        result = http({:method => :get, :raw => true, :path => "statusBar"})
        if result == ""
          RunLoop::log_debug("status_bar_details is only available in Calabash iOS >= 0.20.0")
          RunLoop::log_debug("Using default status bar details based on orientation.")

          if portrait?
            {
              "frame" => {
                "y" => 0,
                "height" => 20,
                "width" => 375,
                "x" => 0
              },
              "hidden" => false,
              "orientation" => status_bar_orientation,
              "warning" => "These are default values.  Update the server to 0.20.0"
            }
          else
            {
              "frame" => {
                "y" => 0,
                "height" => 10,
                "width" => 375,
                "x" => 0
              },
              "hidden" => false,
              "orientation" => status_bar_orientation,
              "warning" => "These are default values.  Update the server to 0.20.0"
            }
          end
        else
          hash = JSON.parse(result)
          hash["results"]
        end
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

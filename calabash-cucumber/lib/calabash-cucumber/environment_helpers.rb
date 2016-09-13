module Calabash
  module Cucumber

    # Methods to expose the runtime environment and details about the device
    # under test.
    #
    # @note
    #  The `OS` environmental variable has been deprecated.  It should never
    #  be set.
    module EnvironmentHelpers

      require "calabash-cucumber/device"

      # Are the uia* methods available?
      #
      # @note
      #  UIAutomation is only available if the app has been launched with
      #  instruments.
      #
      # @return [Boolean] Returns true if the app has been launched with
      #  instruments.
      def uia_available?
        Calabash::Cucumber::Launcher.instruments?
      end

      # Are the uia* methods un-available?
      #
      # @note
      #  UIAutomation is only available if the app has been launched with
      #  instruments.
      #
      # @return [Boolean] Returns true if the app has been not been launched with
      #  instruments.
      def uia_not_available?
        not uia_available?
      end

      # Are we running in the Xamarin Test Cloud?
      #
      # @return [Boolean] Returns true if cucumber is running in the test cloud.
      def xamarin_test_cloud?
        ENV['XAMARIN_TEST_CLOUD'] == '1'
      end

      # Returns the default Device that is connected the current launcher.
      #
      # @return [Calabash::Cucumber::Device] An instance of Device.
      def default_device
        require "calabash-cucumber/launcher"
        l = Calabash::Cucumber::Launcher.launcher_if_used
        l && l.device
      end

      # Is the device under test an iPad?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test is an iPad.
      def ipad?
        _default_device_or_create.ipad?
      end

      # Is the device under test an iPhone?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test is an iPhone.
      def iphone?
        _default_device_or_create.iphone?
      end

      # Is the device under test an iPod?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test is an iPod.
      def ipod?
        _default_device_or_create.ipod?
      end

      # Is the device under test an iPad Pro
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test is an iPod.
      def ipad_pro?
        _default_device_or_create.ipad_pro?
      end

      # Is the device under test an iPhone or iPod?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true If device under test is an iPhone or iPod.
      def device_family_iphone?
        iphone? or ipod?
      end

      # Is the device under test a simulator?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test is a simulator.
      def simulator?
        _default_device_or_create.simulator?
      end

      # Is the device under test have a 4 inch screen?
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if device under test has a 4in screen.
      def iphone_4in?
        _default_device_or_create.iphone_4in?
      end

      # Is the device under test an iPhone 6.
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if this device is an iPhone 6
      def iphone_6?
        _default_device_or_create.iphone_6?
      end

      # Is the device under test an iPhone 6+?
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if this device is an iPhone 6+
      def iphone_6_plus?
        _default_device_or_create.iphone_6_plus?
      end

      # Is the device under test an iPhone 3.5in?
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if this device is an iPhone 3.5in?
      def iphone_35in?
        _default_device_or_create.iphone_35in?
      end

      # The iOS version on the device under test.
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [RunLoop::Version] The version of the iOS running on the device.
      def ios_version
        require "run_loop/version"
        RunLoop::Version.new(_default_device_or_create.ios_version)
      end

      # The screen dimensions of the device under test.
      #
      # This is a hash of form:
      #  {
      #    :sample => 1,
      #    :height => 1334,
      #    :width => 750,
      #    :scale" => 2
      #  }
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [RunLoop::Version] The version of the iOS running on the device.
      def screen_dimensions
        _default_device_or_create.screen_dimensions
      end

      # Is the device under test running iOS 5?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 5
      def ios5?
         _default_device_or_create.ios5?
      end

      # Is the device under test running iOS 6?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 6
      def ios6?
        _default_device_or_create.ios6?
      end

      # Is the device under test running iOS 7?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 7
      def ios7?
        _default_device_or_create.ios7?
      end

      # Is the device under test running iOS 8?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 8
      def ios8?
       _default_device_or_create.ios8?
      end

      # Is the device under test running iOS 9?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 9
      def ios9?
       _default_device_or_create.ios9?
      end

      # Is the app that is being tested an iPhone app emulated on an iPad?
      #
      # @see Calabash::Cucumber::IPad
      #
      # @raise [RuntimeError] If the server cannot be reached.
      # @return [Boolean] true if app is being emulated on an iPad.
      def iphone_app_emulated_on_ipad?
        _default_device_or_create.iphone_app_emulated_on_ipad?
      end

      private
      # @!visibility private
      # Returns the device that is currently being tested against.
      #
      # Returns the device attr of `Calabash::Cucumber::Launcher` if
      # it is defined.  otherwise, creates a new `Calabash::Cucumber::Device`
      # by querying the server.
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Calabash::Cucumber::Device] an instance of Device
      def _default_device_or_create
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version)
        end
        device
      end
    end
  end
end

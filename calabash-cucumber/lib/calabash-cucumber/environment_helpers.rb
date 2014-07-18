require 'calabash-cucumber/device'
require 'calabash-cucumber/launcher'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Methods to expose the runtime environment and details about the device
    # under test.
    #
    # @note
    #  The `OS` environmental variable has been deprecated.  It should never
    #  be set.
    module EnvironmentHelpers

      include Calabash::Cucumber::Logging

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
        l = Calabash::Cucumber::Launcher.launcher_if_used
        l && l.device
      end

      # Is the device under test an iPad?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is an iPad.
      def ipad?
        _default_device_or_create().ipad?
      end

      # Is the device under test an iPhone?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is an iPhone.
      def iphone?
        _default_device_or_create().iphone?
      end

      # Is the device under test an iPod?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is an iPod.
      def ipod?
        _default_device_or_create().ipod?
      end

      # Is the device under test an iPhone or iPod?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is an iPhone or iPod.
      def device_family_iphone?
        iphone? or ipod?
      end

      # Is the device under test a simulator?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is a simulator.
      def simulator?
        _default_device_or_create().simulator?
      end

      # @deprecated 0.9.168 replaced with `iphone_4in?`
      # @see #iphone_4in?
      def iphone_5?
        _deprecated('0.9.168', "use 'iphone_4in?' instead", :warn)
        iphone_4in?
      end

      # Does the device under test have 4in screen?
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test has a 4in screen.
      def iphone_4in?
        _default_device_or_create().iphone_4in?
      end

      # Is the device under test running iOS 5?
      #
      # @note
      #  **WARNING:** The `OS` env variable has been deprecated and should
      #  never be set.
      #
      # @note
      #  **WARNING:* Setting the `OS` env variable will override the value returned
      #  by querying the device.
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 5
      def ios5?
        _OS_ENV.eql?(_canonical_os_version(:ios5)) || _default_device_or_create().ios5?
      end

      # Is the device under test running iOS 6?
      #
      # @note
      #  **WARNING:** The `OS` env variable has been deprecated and should
      #  never be set.
      #
      # @note
      #  **WARNING:* Setting the `OS` env variable will override the value returned
      #  by querying the device.
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 6
      def ios6?
        _OS_ENV.eql?(_canonical_os_version(:ios6)) || _default_device_or_create().ios6?
      end


      # Is the device under test running iOS 7?
      #
      # @note
      #  **WARNING:** The `OS` env variable has been deprecated and should
      #  never be set.
      #
      # @note
      #  **WARNING:* Setting the `OS` env variable will override the value returned
      #  by querying the device.
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if device under test is running iOS 7
      def ios7?
        _OS_ENV.eql?(_canonical_os_version(:ios7)) || _default_device_or_create().ios7?
      end

      # Is the app that is being tested an iPhone app emulated on an iPad?
      #
      # @see Calabash::Cucumber::IPad
      #
      # @raise [RuntimeError] if the server cannot be reached
      # @return [Boolean] true if app is being emulated on an iPad.
      def iphone_app_emulated_on_ipad?
        _default_device_or_create().iphone_app_emulated_on_ipad?
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
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device
      end

      # Returns the value of the environmental variable OS.
      #
      # @note
      #  The `OS` env has been deprecated for some time.  It should never be set.
      def _OS_ENV
        ENV['OS']
      end

      # @!visibility private
      CANONICAL_IOS_VERSIONS = {:ios5 => 'ios5',
                                :ios6 => 'ios6',
                                :ios7 => 'ios7'}


      # Returns the canonical value iOS versions as strings.
      def _canonical_os_version(key)
        CANONICAL_IOS_VERSIONS[key]
      end
    end
  end
end

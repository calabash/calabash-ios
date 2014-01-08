require 'calabash-cucumber/device'
require 'calabash-cucumber/launcher'

module Calabash
  module Cucumber
    module EnvironmentHelpers


      # returns +true+ if UIAutomation functions are available
      #
      # UIAutomation is only available if the app has been launched with
      # Instruments
      def uia_available?
        Calabash::Cucumber::Launcher.instruments?
      end

      # returns +true+ if UIAutomation functions are not available
      #
      # UIAutomation is only available if the app has been launched with
      # Instruments
      def uia_not_available?
        not uia_available?
      end

      # returns +true+ if cucumber is running in the test cloud
      def xamarin_test_cloud?
        ENV['XAMARIN_TEST_CLOUD'] == '1'
      end

      # returns the default Device
      def default_device
        l = Calabash::Cucumber::Launcher.launcher_if_used
        l && l.device
      end

      # returns +true+ if the target device is an ipad
      #
      # raises an error if the server cannot be reached
      def ipad?
        _default_device_or_create().ipad?
      end

      # returns +true+ if the target device is an iphone
      #
      # raises an error if the server cannot be reached
      def iphone?
        _default_device_or_create().iphone?
      end

      # returns +true+ if the target device is an ipod
      #
      # raises an error if the server cannot be reached
      def ipod?
        _default_device_or_create().ipod?
      end
      
      # returns +true+ if the target device is an iphone or ipod
      #
      # raises an error if the server cannot be reached
      def device_family_iphone?
        iphone? or ipod?
      end

      # returns +true+ if the target device is a simulator (not a physical device)
      #
      # raises an error if the server cannot be reached
      def simulator?
        _default_device_or_create().simulator?
      end

      # returns +true+ if the target device or simulator is a 4in model
      #
      # raises an error if the server cannot be reached
      def iphone_5?
        _default_device_or_create().iphone_5?
      end

      # returns +true+ if the target device or simulator is a 4in model
      #
      # raises an error if the server cannot be reached
      def iphone_4in?
        iphone_5?
      end

      # returns +true+ if the OS major version is 5
      #
      # raises an error if the server cannot be reached
      #
      # WARNING: setting the +OS+ env variable will override the value returned
      #          by querying the device
      def ios5?
        _OS_ENV.eql?(_canonical_os_version(:ios5)) || _default_device_or_create().ios5?
      end

      # returns +true+ if the OS major version is 6
      #
      # raises an error if the server cannot be reached
      #
      # WARNING: setting the +OS+ env variable will override the value returned
      #          by querying the device
      def ios6?
        _OS_ENV.eql?(_canonical_os_version(:ios6)) || _default_device_or_create().ios6?
      end


      # returns +true+ if the OS major version is 7
      #
      # raises an error if the server cannot be reached
      #
      # WARNING: setting the +OS+ env variable will override the value returned
      #          by querying the device
      def ios7?
        _OS_ENV.eql?(_canonical_os_version(:ios7)) || _default_device_or_create().ios7?
      end

      # returns +true+ if the app is an iphone app emulated on an ipad
      #
      # raises an error if the server cannot be reached
      def iphone_app_emulated_on_ipad?
        _default_device_or_create().iphone_app_emulated_on_ipad?
      end

      # returns +true+ if the <tt>CALABASH_NO_DEPRECATION</tt> variable is set
      # to +1+
      def no_deprecation_warnings?
        ENV['CALABASH_NO_DEPRECATION'] == '1'
      end

      # returns +true+ if the <tt>CALABASH_FULL_CONSOLE_OUTPUT</tt> is set to
      # +1+
      def full_console_logging?
        ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
      end

      # returns +true+ if the <tt>DEBUG</tt> is set to +1+
      def debug_logging?
        ENV['DEBUG'] == '1'
      end


      # prints a deprecated message that includes the line number
      #   +version+ string indicating when the feature was deprecated
      #   +msg+ deprecation message (possibly suggesting alternatives)
      #   +type+ <tt>{ :warn | :pending }</tt> - <tt>:pending</tt> will raise a
      #          cucumber pending exception
      #
      # if ENV['CALABASH_NO_DEPRECATION'] == '1' then this method is a nop
      def _deprecated(version, msg, type)
        allowed = [:pending, :warn]
        unless allowed.include?(type)
          screenshot_and_raise "type '#{type}' must be on of '#{allowed}'"
        end

        unless no_deprecation_warnings?


          if RUBY_VERSION < '2.0'
            stack = Kernel.caller()[1..6].join("\n")
          else
            stack = Kernel.caller(0, 6)[1..-1].join("\n")
          end

          msg = "deprecated '#{version}' - '#{msg}'\n#{stack}"

          if type.eql?(:pending)
            pending(msg)
          else
            # todo deprecated function does not output on a new line when called within cucumber
            # todo should the _deprecated function be colored?
            begin
              warn "\033[34m\nWARN: #{msg}\033[0m"
            rescue
              warn "\nWARN: #{msg}"
            end
          end
        end
      end

      private
      # returns the device that is currently being tested against
      #
      # returns the +device+ attr of <tt>Calabash::Cucumber::Launcher</tt> if
      # it is defined.  otherwise, creates a new <tt>Calabash::Cucumber::Device</tt>
      # by querying the server.
      #
      # raises an error if the server cannot be reached
      def _default_device_or_create
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device
      end

      # returns the value of the environmental variable +OS+
      def _OS_ENV
        ENV['OS']
      end

      CANONICAL_IOS_VERSIONS = {:ios5 => 'ios5',
                                :ios6 => 'ios6',
                                :ios7 => 'ios7'}


      # returns the canonical value iOS versions as strings
      def _canonical_os_version(key)
        CANONICAL_IOS_VERSIONS[key]
      end
    end
  end
end

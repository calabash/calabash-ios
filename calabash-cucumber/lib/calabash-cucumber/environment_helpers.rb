require 'calabash-cucumber/core'
require 'calabash-cucumber/device'

module Calabash
  module Cucumber
    module EnvironmentHelpers

      # returns +true+ if UIAutomation functions are available
      #
      # UIAutomation is only available if the app has been launched with
      # Instruments
      def uia_available?
        uia?
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

      # returns +true+ if the target device is an ipad
      #
      # raises an error if the server cannot be reached
      def ipad?
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device.ipad?
      end

      # returns +true+ if the target device is an iphone
      #
      # raises an error if the server cannot be reached
      def iphone?
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device.iphone?
      end

      # returns +true+ if the target device is a simulator (not a physical device)
      #
      # raises an error if the server cannot be reached
      def simulator?
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device.simulator?
      end

      # returns +true+ if the OS major version is 5
      #
      # raises an error if the server cannot be reached
      def ios5?
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device.ios5?
      end

      # returns +true+ if the OS major version is 6
      #
      # raises an error if the server cannot be reached
      def ios6?
        device = default_device
        if device.nil?
          device = Calabash::Cucumber::Device.new(nil, server_version())
        end
        device.ios6?
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


      # todo deprecated function does not output on a new line when called within cucumber
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
          info = Kernel.caller.first

          msg = "deprecated '#{version}' - '#{msg}'\n#{info}"

          if type.eql?(:pending)
            pending(msg)
          else
            warn "\nWARN: #{msg}"
          end
        end
      end

    end
  end
end

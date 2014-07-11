require 'json'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # Device encapsulates information about the device or simulator that the
    # app is running on.  It also includes the following information about the
    # app that is running on the current device.
    #
    # * The version of the embedded Calabash server.
    # * Whether or not the app is an iPhone-only app that is being emulated on
    #   an iPad.
    class Device

      include Calabash::Cucumber::Logging

      # @!visibility private
      GESTALT_IPHONE = 'iPhone'

      # @!visibility private
      GESTALT_IPAD = 'iPad'

      # @!visibility private
      GESTALT_IPHONE5 = '4-inch'

      # @!visibility private
      GESTALT_SIM_SYS = 'x86_64'

      # @!visibility private
      GESTALT_IPOD = 'iPod'

      # @!attribute [r] endpoint
      # The http address of this device.
      # @example
      #  http://192.168.0.2:37265
      # @return [String] an ip address with port number.
      attr_reader :endpoint

      # The device family of this device.
      #
      # @note Also know as the form factor.
      #
      # @example
      #  # will be one of
      #  iPhone
      #  iPod
      #  iPad
      #
      # @!attribute [r] device_family
      # @return [String] the device family
      attr_reader :device_family

      # @!visibility private
      # @attribute [r] simulator_details
      # @return [String] Additional details about the simulator.  If this device
      #  is a physical device, returns nil.
      attr_reader :simulator_details

      # The `major.minor.[.patch]` version of iOS that is running on this device.
      #
      # @example
      #  7.1
      #  6.1.2
      #  5.1.1
      #
      # @attribute [r] ios_version
      # @return [String] the version of the iOS that is running on this device
      attr_reader :ios_version

      # The hardware architecture of this device.  Also known as the chip set.
      #
      # @example
      #  # simulator
      #  i386
      #  x86_64
      #
      # @example
      #  # examples from physical devices
      #  armv6
      #  armv7s
      #  arm64
      #
      # @attribute [r] system
      # @return [String] the hardware architecture of this device.
      #  this device.
      attr_reader :system

      # The version of the embedded Calabash server that is running in the
      # app under test on this device.
      #
      # @example
      #  0.9.168
      #  0.10.0.pre1
      #
      # @attribute [r] server_version
      # @return [String] the major.minor.patch[.pre\d] version of the embedded
      #  Calabash server
      attr_reader :server_version

      # Indicates whether or not the app under test on this device is an
      #  iPhone-only app that is being emulated on an iPad.
      #
      # @note If the `1x` or `2x` button is visible, then the app is being
      #  emulated.
      #
      # @attribute [r] iphone_app_emulated_on_ipad
      # @return [Boolean] `true` iff the app under test is emulated
      attr_reader :iphone_app_emulated_on_ipad

      # Indicates whether or not this device has a 4in screen.
      # @attribute [r] iphone_4in
      # @return [Boolean] `true` iff this device has a 4in screen.
      attr_reader :iphone_4in

      # @!attribute [rw] udid
      # @return [String] The udid of this device.
      attr_accessor :udid

      # Creates a new instance of Device.
      #
      # @see Calabash::Cucumber::Core#server_version
      #
      # @param [String] endpoint the http address of this device
      # @param [Hash] version_data the output of the `server_version` function
      # @return [Device] a new Device instance
      def initialize (endpoint, version_data)
        simulator_device = version_data['simulator_device']
        @endpoint = endpoint
        @system = version_data['system']
        @device_family = @system.eql?(GESTALT_SIM_SYS) ? simulator_device : @system.split(/[\d,.]/).first
        @simulator_details = version_data['simulator']
        @ios_version = version_data['iOS_version']
        @server_version = version_data['version']
        @iphone_app_emulated_on_ipad = version_data['iphone_app_emulated_on_ipad']
        @iphone_4in = version_data['4inch']
      end

      def simulator?
        system.eql?(GESTALT_SIM_SYS)
      end

      def device?
        not simulator?
      end

      def iphone?
        device_family.eql? GESTALT_IPHONE
      end

      def ipod?
        device_family.eql? GESTALT_IPOD
      end

      def ipad?
        device_family.eql? GESTALT_IPAD
      end

      def iphone_4in?
        @iphone_4in
      end

      def iphone_5?
        _deprecated('0.9.168', "use 'iphone_4in?' instead", :warn)
        iphone_4in?
      end

      def version_hash (version_str)
        tokens = version_str.split(/[,.]/)
        {:major_version => tokens[0],
         :minor_version => tokens[1],
         :bug_version => tokens[2]}
      end

      def ios_major_version
        version_hash(ios_version)[:major_version]
      end

      def ios7?
        ios_major_version.eql?('7')
      end

      def ios6?
        ios_major_version.eql?('6')
      end

      def ios5?
        ios_major_version.eql?('5')
      end

      def screen_size
        return { :width => 768, :height => 1024 } if ipad?
        return { :width => 320, :height => 568 } if iphone_4in?
        { :width => 320, :height => 480 }
      end

      def iphone_app_emulated_on_ipad?
        iphone_app_emulated_on_ipad
      end

      def framework_version
        _deprecated('0.9.169', "use 'server_version', instead", :warn)
        @server_version
      end

    end
  end
end

require 'json'

module Calabash
  module Cucumber

    # Device encapsulates information about the device or simulator that the
    # app is running on.  It also includes the following information about the
    # app that is running on the current device.
    #
    # * The version of the embedded Calabash server.
    # * Whether or not the app is an iPhone-only app that is being emulated on
    #   an iPad.
    class Device < Calabash::Device

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

      def initialize(identifier, server, options={})
        super(identifier, server, options)
        @has_fetched_device_info = false
      end

      # http call
      # return [Hash] A hash of information about this device.
      def fetch_device_info
        request = Calabash::HTTP::Request.new('version')
        body = http_client.get(request).body
        begin
          JSON.parse(body)
        rescue TypeError, JSON::ParserError => _
          raise "Could not parse response '#{body}'; the app has probably crashed"
        end
      end

      def extract_device_info!(version_data)
        simulator_device = version_data['simulator_device']
        @system = version_data['system']
        @device_family = @system.eql?(GESTALT_SIM_SYS) ? simulator_device : @system.split(/[\d,.]/).first
        @simulator_details = version_data['simulator']
        @ios_version = version_data['iOS_version']
        @server_version = version_data['version']
        @iphone_app_emulated_on_ipad = version_data['iphone_app_emulated_on_ipad']
        @iphone_4in = version_data['4inch']
        screen_dimensions = version_data['screen_dimensions']
        if screen_dimensions
          @screen_dimensions = {}
          screen_dimensions.each_pair do |key,val|
            @screen_dimensions[key.to_sym] = val
          end
        end
        @has_fetched_device_info = true
      end

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
      # @return [String] The device family.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def device_family
        ensure_version_information_extracted
        @device_family
      end

      # @!visibility private
      # @return [String] Additional details about the simulator.  If this device
      #  is a physical device, returns nil.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def simulator_details
        ensure_version_information_extracted
        @simulator_details
      end

      # The `major.minor.[.patch]` version of iOS that is running on this device.
      #
      # @example
      #  7.1
      #  6.1.2
      #  5.1.1
      #
      # @return [String] the version of the iOS that is running on this device
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios_version
        # @todo Refactor to version
        # @todo Refactor:  might be able to set this using RunLoop::Device
        ensure_version_information_extracted
        @ios_version
      end

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
      # @return [String] The hardware architecture of this device.
      #  this device.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def system
        # @todo Refactor to cpu_architecture
        ensure_version_information_extracted
        @system
      end

      # The version of the embedded Calabash server that is running in the
      # app under test on this device.
      #
      # @example
      #  0.9.168
      #  0.10.0.pre1
      #
      # @return [String] The major.minor.patch[.pre\d] version of the embedded
      #  Calabash server.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def server_version
        ensure_version_information_extracted
        @server_version
      end

      # Device specific screen information.
      #
      # This is a hash of form:
      #
      #  {
      #    :sample => 1,
      #    :height => 1334,
      #    :width => 750,
      #    :scale" => 2
      #  }
      #
      # @return [Hash] The screen dimensions, scale and down/up sampling
      #  fraction of this device.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def screen_dimensions
        ensure_version_information_extracted
        @screen_dimensions
      end

      # Is this device a simulator or physical device?
      # @return [Boolean] Is true if this device is a simulator.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def simulator?
        system.eql?(GESTALT_SIM_SYS)
      end

      # Is this device a device or simulator?
      # @return [Boolean] Is true if this device is a physical device.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def device?
        not simulator?
      end

      # Is this device an iPhone?
      # @return [Boolean] Is true if this device is an iPhone.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def iphone?
        device_family.eql? GESTALT_IPHONE
      end

      # Is this device an iPod?
      # @return [Boolean] Is true if this device is an iPod.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ipod?
        device_family.eql? GESTALT_IPOD
      end

      # Is this device an iPad?
      # @return [Boolean] Is true if this device is an iPad.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ipad?
        device_family.eql? GESTALT_IPAD
      end

      # Is this device a 4 inch iPhone?
      # @return [Boolean] Is true if this device is a 4 inch iPhone
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def iphone_4in?
        # @todo Refactor to iphone_4_inch?
        ensure_version_information_extracted
        @iphone_4in
      end

      # The major iOS version of this device.
      # @return [String] The major version of the OS.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios_major_version
        version_hash(ios_version)[:major_version]
      end

      # Is this device running iOS 8?
      # @return [Boolean] Is true if the major version of the OS is 8.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios8?
        ios_major_version.eql?('8')
      end

      # Is this device running iOS 7?
      # @return [Boolean] Is true if the major version of the OS is 7.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios7?
        ios_major_version.eql?('7')
      end

      # Is this device running iOS 6?
      # @return [Boolean] true if the major version of the OS is 6.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios6?
        ios_major_version.eql?('6')
      end

      # Is this device running iOS 5?
      # @return [Boolean] Is true if the major version of the OS is 5.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def ios5?
        ios_major_version.eql?('5')
      end

      # Is the app that is running an iPhone-only app emulated on an iPad?
      #
      # @note If the app is running in emulation mode, there will be a 1x or 2x
      #   scale button visible on the iPad.
      #
      # @return [Boolean] Is true if the app running on this devices is an
      #   iPhone-only app emulated on an iPad.
      # @raise [RuntimeError] Raises error if device information has not been
      #  fetched from the server.  Device information is available after a
      #  call to Device.calabash_start_app.
      def iphone_app_emulated_on_ipad?
        ensure_version_information_extracted
        @iphone_app_emulated_on_ipad
      end

      private

      # @!visibility private
      def version_hash(version_str)
        tokens = version_str.split(/[,.]/)
        {:major_version => tokens[0],
         :minor_version => tokens[1],
         :bug_version => tokens[2]}
      end

      # @!visibility private
      # @raise [RuntimeError] Raises an error if device info has not been
      #  fetched from the server and parsed.
      def ensure_version_information_extracted
        unless has_fetched_device_info?
          raise 'Must be called after Device.calabash_start_app'
        end
      end

      # @!visibility private
      # Has extract_device_info! been called?
      def has_fetched_device_info?
        @has_fetched_device_info
      end
    end
  end
end

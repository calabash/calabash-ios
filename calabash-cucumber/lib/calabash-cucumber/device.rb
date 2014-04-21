require 'json'

module Calabash
  module Cucumber
    # Class device encapsulates information about the device or devices we are
    # interacting with during a test.
    class Device

      GESTALT_IPHONE = 'iPhone'
      GESTALT_IPAD = 'iPad'
      GESTALT_IPHONE5 = '4-inch'
      GESTALT_SIM_SYS = 'x86_64'
      GESTALT_IPOD = 'iPod'

      attr_reader :endpoint
      attr_reader :device_family
      attr_reader :simulator_details, :ios_version
      attr_reader :system
      attr_reader :server_version
      attr_reader :iphone_app_emulated_on_ipad
      attr_reader :iphone_4in

      attr_accessor :udid

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

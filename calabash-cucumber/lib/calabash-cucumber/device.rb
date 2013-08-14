require 'json'

module Calabash
  module Cucumber
    # Class device encapsulates information about the device or devices
    # we are interacting with during a test.
    # Credit: Due to jmoody's briar: https://github.com/jmoody/briar/blob/master/lib/briar/gestalt.rb

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
      attr_reader :framework_version

      attr_accessor :udid

      def initialize (endpoint, version_data)
        simulator_device = version_data['simulator_device']
        @endpoint = endpoint
        @system = version_data['system']
        @device_family = @system.eql?(GESTALT_SIM_SYS) ? simulator_device : @system.split(/[\d,.]/).first
        @simulator_details = version_data['simulator']
        @ios_version = version_data['iOS_version']
        @framework_version = version_data['version']
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

      def iphone_5?
        if simulator?
          !simulator_details.scan(GESTALT_IPHONE5).empty?
        else
          system.split(/[\D]/).delete_if { |x| x.eql?('') }.first.eql?('5')
        end
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
    end
  end
end

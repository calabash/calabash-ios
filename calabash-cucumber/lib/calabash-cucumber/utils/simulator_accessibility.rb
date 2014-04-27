require 'calabash-cucumber/utils/xctools'
require 'calabash-cucumber/utils/plist_buddy'
require 'sim_launcher'

module Calabash
  module Cucumber

    # methods for checking and setting simulator accessibility
    module SimulatorAccessibility

      include Calabash::Cucumber::XcodeTools
      include Calabash::Cucumber::PlistBuddy

      def quit_simulator
        dev_dir = xcode_developer_dir
        system "/usr/bin/osascript -e 'tell application \"#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to quit'"
      end

      def reset_simulator_content_and_settings
        sim_lib_path = File.join(simulator_app_support_dir(), 'Library')
        FileUtils.rm_rf(sim_lib_path)
        simulator_support_sdk_dirs.each do |dir|
          FileUtils.rm_rf(dir)
        end
      end

      def enable_accessibility_in_sdk_dir(sim_app_support_sdk_dir)
        quit_simulator
        plist_path = File.expand_path("#{sim_app_support_sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

        hash = accessibility_properties_hash()
        plist_set(hash[:access_enabled], 'bool', 'true', plist_path)
        plist_set(hash[:app_access_enabled], 'bool', 'true', plist_path)
        plist_set(hash[:automation_enabled], 'bool', 'true', plist_path)

        plist_set(hash[:inspector_showing], 'bool', 'false', plist_path)
        plist_set(hash[:inspector_full_size], 'bool', 'false', plist_path)
        plist_set(hash[:inspector_frame], 'string', '{{270, -13}, {276, 166}}', plist_path)
      end

      def enable_accessibility_on_simulators
        simulator_support_sdk_dirs.each do |dir|
          enable_accessibility_in_sdk_dir(dir)
        end
      end

      @private

      def accessibility_properties_hash
        {
              # this is required
              :access_enabled => 'AccessibilityEnabled',
              # i _think_ this is legacy
              :app_access_enabled => 'ApplicationAccessibilityEnabled',

              # i don't know what this does
              :automation_enabled => 'AutomationEnabled',

              # determines if the Accessibility Inspector is showing
              :inspector_showing => 'AXInspectorEnabled',
              # controls if the Accessibility Inspector is expanded or not expanded
              :inspector_full_size => 'AXInspector.enabled',
              # controls the frame of the Accessibility Inspector
              # this is a 'string' => {{0, 0}, {276, 166}}
              :inspector_frame => 'AXInspector.frame'
        }
      end

      def simulator_app_support_dir
        File.expand_path('~/Library/Application Support/iPhone Simulator')
      end

      def simulator_support_sdk_dirs
        sim_app_support_path = simulator_app_support_dir()
        Dir.glob("#{sim_app_support_path}/*").select { |path|
          path =~ /(\d)\.(\d)\.?(\d)?(-64)?/
        }
      end

    end
  end
end
require 'calabash-cucumber/utils/xctools'
require 'calabash-cucumber/utils/plist_buddy'
require 'sim_launcher'
require 'cfpropertylist'

module Calabash
  module Cucumber

    # methods for checking and setting simulator accessibility
    module SimulatorAccessibility

      include Calabash::Cucumber::XcodeTools
      include Calabash::Cucumber::PlistBuddy

      # quits the iOS Simulator
      #
      # ATM there can only be only simulator open at a time, so simply doing
      # what the sim_launcher gem does:
      #
      #    def quit_simulator
      #      `echo 'application "iPhone Simulator" quit' | osascript`
      #    end
      #
      # works.  I am not sure if we will ever be able to launch more than one
      # simulator, but in case we can, this method will quit the simulator
      # that is indicated by +xcode-select+ or +DEVELOPER_DIR+.
      def quit_simulator
        dev_dir = xcode_developer_dir
        system "/usr/bin/osascript -e 'tell application \"#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to quit'"
      end

      # launches the iOS Simulator indicated by +xcode-select+ or +DEVELOPER_DIR+
      def launch_simulator
        dev_dir = xcode_developer_dir
        system "open -a \"#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\""
      end

      # resets the simulator content and settings.  it is analogous to touching
      # the menu item.
      #
      # it works by deleting the following directories:
      #
      # * ~/Library/Application Support/iPhone Simulator/Library
      # * ~/Library/Application Support/iPhone Simulator/Library/<sdk>[-64]
      #
      # and relaunching the iOS Simulator which will recreate the Library
      # directory and the latest SDK directory.
      def reset_simulator_content_and_settings
        quit_simulator
        sim_lib_path = File.join(simulator_app_support_dir(), 'Library')
        FileUtils.rm_rf(sim_lib_path)
        existing_simulator_support_sdk_dirs.each do |dir|
          FileUtils.rm_rf(dir)
        end

        launch_simulator

        # this is tricky because we need to wait for the simulator to recreate
        # the directories.  specifically, we need the Accessibility plist to be
        # exist so subsequent calabash launches will be able to enable
        # accessibility.
        #
        # the directories take ~3.0 - ~5.0 to create.
        counter = 0
        loop do
          break if counter == 80
          dirs = existing_simulator_support_sdk_dirs
          if dirs.count == 0
            sleep(0.2)
          else
            break if dirs.all? { |dir|
              plist = File.expand_path("#{dir}/Library/Preferences/com.apple.Accessibility.plist")
              File.exists?(plist)
            }
            sleep(0.2)
          end
          counter = counter + 1
        end
      end

      # enables accessibility on any existing iOS Simulator by adjusting the
      # simulator's Library/Preferences/com.apple.Accessibility.plist contents.
      #
      # a simulator 'exists' if has an Application Support directory. for
      # example, the 6.1, 7.0.3-64, and 7.1 simulators exist if the following
      # directories are present:
      #
      #     ~/Library/Application Support/iPhone Simulator/Library/6.1
      #     ~/Library/Application Support/iPhone Simulator/Library/7.0.3-64
      #     ~/Library/Application Support/iPhone Simulator/Library/7.1
      #
      # a simulator is 'possible' if the SDK is available in the Xcode version.
      #
      # this method merges (uniquely) the possible and existing SDKs.
      #
      # this method also hides the AXInspector.
      #
      # @param [Hash] opts controls the behavior of the method
      # @option opts [Boolean] :verbose controls logging output
      # @return [Boolean] true iff enabling accessibility worked on all sdk
      #  directories
      def enable_accessibility_on_simulators(opts={})
        possible = possible_simulator_support_sdk_dirs
        existing = existing_simulator_support_sdk_dirs
        dirs = (possible + existing).uniq
        results = dirs.map do |dir|
          enable_accessibility_in_sdk_dir(dir, opts)
        end
        results.all? { |elm| elm }
      end

      @private

      # enables accessibility on the simulator indicated by
      # +sim_app_support_sdk_dir+.
      #
      # WARNING:  this will quit the simulator
      #
      #   path = '/6.1'
      #   enable_accessibility_in_sdk_dir(path)
      #
      # this method also hides the AXInspector.
      #
      # if the Library/Preferences/com.apple.Accessibility.plist does not exist
      # this method will create a Library/Preferences/com.apple.Accessibility.plist
      # that (oddly) the Simulator will _not_ overwrite.
      #
      # @see enable_accessibility_on_simulators for the public API.
      #
      # @param [String] sim_app_support_sdk_dir the directory where the
      #   Library/Preferences/com.apple.Accessibility.plist can be found.
      #
      # @param [Hash] opts controls the behavior of the method
      # @option opts [Boolean] :verbose controls logging output
      # @return [Boolean] iff the plist exists and the plist was successfully
      #   updated.
      def enable_accessibility_in_sdk_dir(sim_app_support_sdk_dir, opts={})
        default_opts = {:verbose => false}
        merged = default_opts.merge(opts)

        quit_simulator

        verbose = merged[:verbose]
        sdk = File.basename(sim_app_support_sdk_dir)
        msgs = ["cannot enable accessibility for #{sdk} SDK"]

        plist_path = File.expand_path("#{sim_app_support_sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

        hash = accessibility_properties_hash()

        if File.exist?(plist_path)
          res = hash.map do |hash_key, settings|
            success = plist_set(settings[:key], settings[:type], settings[:value], plist_path)
            unless success
              if verbose
                if settings[:type] == 'bool'
                  value = settings[:value] ? 'YES' : 'NO'
                else
                  value = settings[:value]
                end
                msgs << "could not set #{hash_key} => '#{settings[:key]}' to #{value}"
                calabash_warn(msgs.join("\n"))
              end
            end
            success
          end
          res.all? { |elm| elm }
        else
          FileUtils.mkdir_p("#{sim_app_support_sdk_dir}/Library/Preferences")
          plist = CFPropertyList::List.new
          data = {}
          # CFPropertyList gem is super wonky
          # it matches Boolean to a string type with 'true/false' values
          # - stick with PlistBuddy
          # hash.each do |_, settings|
          #   data[settings[:key]] = settings[:value]
          # end
          plist.value = CFPropertyList.guess(data)
          plist.save(plist_path, CFPropertyList::List::FORMAT_BINARY)
          enable_accessibility_in_sdk_dir(sim_app_support_sdk_dir)
        end
      end


      # a hash table of the accessibility properties that control whether or not
      # accessibility is enabled and whether the AXInspector is visible.
      # @return [Hash] table of accessibility properties found in the
      #  Library/Preferences/com.apple.Accessibility.plist
      def accessibility_properties_hash
        {
              # this is required
              :access_enabled => {:key => 'AccessibilityEnabled',
                                  :value => 'true',
                                  :type => 'bool'},
              # i _think_ this is legacy
              :app_access_enabled => {:key => 'ApplicationAccessibilityEnabled',
                                      :value => 'true',
                                      :type => 'bool'},

              # i don't know what this does
              :automation_enabled => {:key => 'AutomationEnabled',
                                      :value => 'true',
                                      :type => 'bool'},

              # determines if the Accessibility Inspector is showing
              :inspector_showing => {:key => 'AXInspectorEnabled',
                                     :value => 'false',
                                     :type => 'bool'},

              # controls if the Accessibility Inspector is expanded or not expanded
              :inspector_full_size => {:key => 'AXInspector.enabled',
                                       :value => 'false',
                                       :type => 'bool'},

              # controls the frame of the Accessibility Inspector
              # this is a 'string' => {{0, 0}, {276, 166}}
              :inspector_frame => {:key => 'AXInspector.frame',
                                   :value => '{{270, -13}, {276, 166}}',
                                   :type => 'string'}
        }
      end

      # the absolute path to the iPhone Simulator Application Support directory
      # @return [String] absolute path
      def simulator_app_support_dir
        File.expand_path('~/Library/Application Support/iPhone Simulator')
      end

      # the absolute path to the SDK's com.apple.Accessibility.plist file
      # @param [String] sdk_dir base path the SDK directory
      # @return [String] an absolute path
      def plist_path_with_sdk_dir(sdk_dir)
        File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
      end

      # returns a list of absolute paths the existing simulator directories.
      #
      # a simulator 'exists' if has an Application Support directory. for
      # example, the 6.1, 7.0.3-64, and 7.1 simulators exist if the following
      # directories are present:
      #
      #     ~/Library/Application Support/iPhone Simulator/Library/6.1
      #     ~/Library/Application Support/iPhone Simulator/Library/7.0.3-64
      #     ~/Library/Application Support/iPhone Simulator/Library/7.1
      #
      # @return[Array<String>] a list of absolute paths to simulator directories
      def existing_simulator_support_sdk_dirs
        sim_app_support_path = simulator_app_support_dir()
        Dir.glob("#{sim_app_support_path}/*").select { |path|
          path =~ /(\d)\.(\d)\.?(\d)?(-64)?/
        }
      end

      # returns a list of possible SDKs per Xcode version
      #
      # it is not enough to ask for the available sdks because of the new 64-bit
      # variants that started to appear Xcode 5 and the potential for patch level
      # versions.
      #
      # unfortunately, this method will need be maintained per Xcode version.
      #
      # @return [Array<String>] ex. ['6.1', '7.1', '7.0.3', '7.0.3-64']
      def possible_simulator_sdks
        sdk_detector = SimLauncher::SdkDetector.new
        available = sdk_detector.available_sdk_versions
        instruments_version = instruments(:version)

        # in Xcode 5.1* SDK 7.0 ==> 7.0.3
        if (instruments_version == '5.1' or instruments_version == '5.1.1') and available.include?('7.0')
          available << '7.0.3'
          available << '7.0.3-64'
        end

        if instruments_version == '5.1.1' and available.include?('7.1')
          available << '7.1'
          available << '7.1-64'
        end

        gem_compat_xcode_versions = ['5.1', '5.1.1']
        unless gem_compat_xcode_versions.include?(instruments_version)
          msg = ["expected Xcode instruments version to be '5.1' or '5.1.1'",
                 "but found version '#{instruments_version}'",
                 "Gem needs a manual update for Xcode #{instruments_version}!"].join("\n")
          calabash_warn(msg)
        end

        # in Xcode 5.1* SDK 7.0 ==> 7.0.3 so we should not include '7.0'
        # if the user's support directory already contains a 7.0 and 7.0-64 dir
        # we will detect it by reading from disk.
        (available - ['7.0']).uniq.sort
      end

      # return absolute paths to possible simulator support sdk dirs
      #
      # these directories may or may not exist
      # @return [Array<String>] an array of absolute paths
      def possible_simulator_support_sdk_dirs
        base_dir = simulator_app_support_dir
        possible_simulator_sdks.map { |sdk|
          "#{base_dir}/#{sdk}"
        }
      end

    end
  end
end
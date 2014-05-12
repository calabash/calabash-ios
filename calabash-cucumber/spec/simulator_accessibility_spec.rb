require 'spec_helper'
require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/launcher'
require 'sim_launcher'

include Calabash::Cucumber::SimulatorAccessibility

describe 'simulator accessibility tool' do

  it 'should be able to find the simulator app support directory' do
    path = simulator_app_support_dir
    expect(File.exist?(path)).to be == true
  end

  it 'should be able open and close the simulator' do
    cmd = "ps auxw | grep \"iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" | grep -v grep"

    quit_simulator
    sleep(2)
    expect(`#{cmd}`.split("\n").count).to be == 0

    launch_simulator
    sleep(4)
    expect(`#{cmd}`.split("\n").count).to be == 1
  end

  describe 'enabling accessibility' do

    before(:each) do
      @sim_launcher = SimLauncher::Simulator.new
      @sdk_detector = SimLauncher::SdkDetector.new(@sim_launcher)
      quit_simulator
    end

    def lp_simple_example
      File.expand_path(File.join(__FILE__, '..', 'resources/enable-accessibility/LPSimpleExample-cal.app'))
    end

    def repopulate_sim_app_support_for_sdk(sdk=@sdk_detector.latest_sdk_version)
      path = File.join(simulator_app_support_dir, "#{sdk}")
      unless File.exist?(path)
        calabash_info("repopulating simulator app support for sdk '#{sdk}'")
        quit_simulator
        @sim_launcher.launch_iphone_app(lp_simple_example, sdk)
        sleep(5)
        quit_simulator
      end
    end

    def repopulate_sim_app_support_all
      @sdk_detector.available_sdk_versions.each do |sdk|
        repopulate_sim_app_support_for_sdk(sdk)
      end
    end

    describe 'interacting with simulator app support sdk directories' do
      it 'should be able to find all the sdk directories' do
        repopulate_sim_app_support_all

        expected = @sdk_detector.available_sdk_versions
        actual = simulator_support_sdk_dirs

        calabash_info("sdks = '#{expected}'")
        actual.each { |path|
          calabash_info("sdk path = '#{path}'")
        }

        expect(actual.count).to be == expected.count
      end
    end

    describe 'enable accessibility with no AXInspector' do

      before(:each) do
        reset_simulator_content_and_settings
          existing_simulator_support_sdk_dirs.each do |dir|
            FileUtils.rm_rf(dir)
          end

        @latest_sdk = @sdk_detector.latest_sdk_version
        @device_target = "iPhone Retina (4-inch) - Simulator - iOS #{@latest_sdk}"
        @launch_args =
              {
                    :launch_method => :instruments,
                    :reset => false,
                    :bundle_id => nil,
                    :device => 'iphone',
                    :no_stop => false,
                    :no_launch => false,
                    :sdk_version => @latest_sdk,
                    :app => lp_simple_example,
                    :timeout => 10,
                    :device_target => @device_target,
                    :launch_retries => 1
              }

        @launcher = Calabash::Cucumber::Launcher.new
      end

      it 'should not fail if the com.apple.Accessibility.plist does not exist' do
        dir = File.join(simulator_app_support_dir, "#{@latest_sdk}")
        expect(enable_accessibility_in_sdk_dir(dir, {:verbose => true})).to be == false
      end


      it 'should not be able to launch LPSimpleExample-app b/c accessibility is not enabled' do
        msgs =
              [
                    'Will throw a "ScriptAgent quit unexpectedly" UI dialog!',
                    '',
                    'This dialog is generated because the app failed to a launch',
                    'correctly on the simulator.  I checked run_loop and this is not',
                    'caused by anything there.',
                    '',
                    'AFAICT there is nothing to be done about this.']
        calabash_warn(msgs.join("\n"))
        expect { @launcher.new_run_loop(@launch_args) }.to raise_error(Calabash::Cucumber::Launcher::StartError)
      end

      it 'should be able to enable accessibility for the latest sdk' do
        repopulate_sim_app_support_for_sdk(@latest_sdk)

        # i am not sure we need these tests
        # the are checking the state of the 'clean' accessibility plist
        # which is subject to change
        # plist = File.join(simulator_app_support_dir, "#{@latest_sdk}", 'Library/Preferences/com.apple.Accessibility.plist')
        # hash = accessibility_properties_hash()

        # expect(plist_read(hash[:access_enabled], plist)).to be == 'true'
        # expect(plist_read(hash[:app_access_enabled], plist)).to be == 'true'

        # flickers depending on the state - not a crucial test
        # expect(plist_read(hash[:automation_enabled], plist)).to be == 'true'
        # expect(plist_read(hash[:inspector_showing], plist)).to be == 'false'
        # expect(plist_key_exists?(hash[:inspector_full_size], plist)).to be == false

        # flickers depending on the state - not a crucial test
        # expect(plist_key_exists?(hash[:inspector_frame], plist)).to be == false

        dir = File.join(simulator_app_support_dir, "#{@latest_sdk}")
        enable_accessibility_in_sdk_dir(dir)

        expect(@launcher.new_run_loop(@launch_args)).to be_a(Hash)
      end
    end
  end
end
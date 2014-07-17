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

  it 'should be able to open and close the simulator' do
    cmd = "ps auxw | grep \"iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" | grep -v grep"

    quit_simulator
    sleep(2)
    expect(`#{cmd}`.split("\n").count).to be == 0

    launch_simulator
    sleep(4)
    expect(`#{cmd}`.split("\n").count).to be == 1
  end

  it 'should be able to return a path a com.apple.Accessibility.plist for an SDK' do
    sdk = "#{simulator_app_support_dir}/7.1"
    expected = "#{sdk}/Library/Preferences/com.apple.Accessibility.plist"
    actual = plist_path_with_sdk_dir(sdk)
    expect(actual).to be == expected
  end

  # brittle because some users will not have installed 6.1 or 7.0, but hey, why
  # are them gem dev'ing or gem testing?
  it 'should be able to return possible SDKs' do
    actual = possible_simulator_sdks
    instruments_version = instruments(:version)

    if instruments_version == '5.1' or instruments_version == '5.1.1'
      expected = ['6.1', '7.0.3', '7.0.3-64', '7.1', '7.1-64']
      expect(actual).to be == expected
    else
      pending("Xcode version '#{instruments_version}' is not supported by this test - gem needs update!")
    end
  end

  # brittle because some users will not have installed 6.1 or 7.0, but hey, why
  # are them gem dev'ing or gem testing?
  it 'should be able to return Simulator Support SDK dirs' do
    actual = possible_simulator_support_sdk_dirs
    instruments_version = instruments(:version)
    if instruments_version == '5.1' or instruments_version == '5.1.1'
      expect(actual.count).to be == 5
    else
      pending("Xcode version '#{instruments_version}' is not supported by this test - gem needs update!")
    end
  end

  it 'should be able to find existing simulator support sdk dirs' do
    mocked_support_dir = File.expand_path(File.join(__FILE__, '..', 'resources/enable-accessibility/'))
    expect(self).to receive(:simulator_app_support_dir).and_return(mocked_support_dir)
    actual = existing_simulator_support_sdk_dirs
    expect(actual.count).to be == 5
  end


  describe 'enabling accessibility' do

    before(:each) do
      @sim_launcher = SimLauncher::Simulator.new
      @sdk_detector = SimLauncher::SdkDetector.new(@sim_launcher)
      quit_simulator

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
                  :timeout => 30,
                  :device_target => @device_target,
                  :launch_retries => 1
            }

      @launcher = Calabash::Cucumber::Launcher.new

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

    describe 'on existing SDK directories' do

      before(:each) do
        reset_simulator_content_and_settings
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
        begin
          expect { @launcher.new_run_loop(@launch_args) }.to raise_error(Calabash::Cucumber::Launcher::StartError)
        ensure
          @launcher.stop
        end
      end

      it 'should be able to enable accessibility for the latest sdk' do
        repopulate_sim_app_support_for_sdk(@latest_sdk)

        dir = File.join(simulator_app_support_dir, "#{@latest_sdk}")
        enable_accessibility_in_sdk_dir(dir)

        begin
          expect(@launcher.new_run_loop(@launch_args)).to be_a(Hash)
        ensure
          @launcher.stop
        end

      end
    end

    describe 'on non-existing SDK directories' do
      before(:each) do
        quit_simulator
        sleep(2)
        existing_simulator_support_sdk_dirs.each do |dir|
           FileUtils.rm_rf(dir)
        end

        reset_simulator_content_and_settings

        quit_simulator
        # let the iOS Simulator do what it needs to do at shut-down
        sleep(2)
      end

      it 'should be able to enable accessibility on all possible simulators' do
        enable_accessibility_on_simulators
        @launch_args[:sdk_version] = nil
        @launch_args[:timeout] = 20
        @launch_args[:launch_retries] = 3

        # these configurations correspond to iOS/Hardware configurations that
        # do not exist.  As an example, there is no iOS 6.1 64-bit implementation,
        # so a simulator like:
        #
        # 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 6.1'
        #
        # does not even make sense.
        #
        # ditto for 'iPhone - Simulator - iOS 7.0' - there is no non-retina
        # iOS 7 hardware
        # -1 Apple
        excluded = [
              'iPhone - Simulator - iOS 7.0',
              'iPhone - Simulator - iOS 7.1',
              'iPhone Retina (4-inch 64-bit) - Simulator - iOS 6.1',
              'iPad Retina (64-bit) - Simulator - iOS 6.1'
        ]
        instruments(:sims).each do |simulator|
          if excluded.include?(simulator)
            calabash_warn("skipping simulator '#{simulator}' - instruments passed us an invalid configuration!")
          else
            @launch_args[:device_target] = simulator
            calabash_info("starting simulator '#{simulator}'")
            begin
              expect(@launcher.new_run_loop(@launch_args)).to be_a(Hash)
            rescue Exception => e
              calabash_info "could not launch '#{simulator}' - #{e}"
            ensure
              @launcher.stop
              sleep(2)
            end
          end
        end
      end

    end
  end
end

require 'calabash-cucumber/launcher'
require 'calabash-cucumber/utils/simulator_accessibility'

describe 'Calabash Launcher' do

  UDID = '66h3hfgc466836ehcg72738eh8f322842855d2fd'
  IPHONE_4IN_R_64 = 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1'

  let (:launcher) { Calabash::Cucumber::Launcher.new }

  before(:example) {
    RunLoop::SimControl.terminate_all_sims
  }

  describe '.default_uia_strategy' do
    let (:sim_control) { RunLoop::SimControl.new }

    describe 'raises an error when' do
      it 'DEVICE_TARGET is a simulator, but no such simulator can be found' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)
        device = RunLoop::Device.new('iPad 2', '7.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
        expect(sim_control).to receive(:simulators).and_return([device])
        launch_args = { :device_target => 'iPhone 4s (7.1.2 Simulator)' }
        expect { launcher.default_uia_strategy(launch_args, sim_control) }.to raise_error
      end

      it 'DEVICE_TARGET is a device, but no such device can be found' do
        expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
        #device = RunLoop::Device.new('hat', '7.1.2', 'c272271d6efd8ab3d611d52e5511afe75958f90d')
        xcode_tools = sim_control.xctools
        expect(xcode_tools).to receive(:instruments).with(:devices).and_return([])
        launch_args = { :device_target => 'device' }
        expect { launcher.default_uia_strategy(launch_args, sim_control) }.to raise_error
      end
    end

    describe 'returns :preferences when' do
      it 'Xcode < 6.0 - not a CoreSimulator environment' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        actual = launcher.default_uia_strategy({}, sim_control)
        expect(actual).to be == :preferences
      end

      describe 'Xcode >= 6.0 - DEVICE_TARGET is an iOS < 8 simulator' do
        it "and DEVICE_TARGET is instruments identifier e.g. 'iPad 2 (7.1 Simulator)'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)
          device = RunLoop::Device.new('iPad 2', '7.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.instruments_identifier }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :preferences
        end

        it "and DEVICE_TARGET is simulator UDID e.g. '12EE4E79-D561-46D2-9F80-BB7278E4A883'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('iPhone 4s', '7.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.udid }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :preferences
        end

        it "and DEVICE_TARGET is a simulator with a custom name e.g. 'my simulator'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('my simulator', '7.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.name }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :preferences
        end
      end

      describe 'Xcode >= 6.0 - DEVICE_TARGET is an iOS < 8 device' do
        it 'and DEVICE_TARGET is a device UDID' do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('hat', '7.1.2', 'c272271d6efd8ab3d611d52e5511afe75958f90d')
          xcode_tools = sim_control.xctools
          expect(xcode_tools).to receive(:instruments).with(:devices).and_return([device])
          launch_args = { :device_target => device.udid }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :preferences
        end

        it "and DEVICE_TARGET == 'device'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('hat', '7.1.2', 'c272271d6efd8ab3d611d52e5511afe75958f90d')
          xcode_tools = sim_control.xctools
          expect(xcode_tools).to receive(:instruments).with(:devices).and_return([device])
          launch_args = { :device_target => 'device' }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :preferences
        end
      end
    end

    describe 'returns :shared_element when' do
      it "Xcode >= 6.0 - DEVICE_TARGET == 'simulator'" do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)
        launch_args = { :device_target => 'simulator' }
        actual = launcher.default_uia_strategy(launch_args, sim_control)
        expect(actual).to be == :shared_element
      end

      describe 'Xcode >= 6.0 - DEVICE_TARGET is an iOS >= 8 simulator' do
        it "and DEVICE_TARGET is instruments identifier e.g. 'iPad 2 (8.1 Simulator)'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)
          device = RunLoop::Device.new('iPad 2', '8.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.instruments_identifier }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :shared_element
        end

        it "and DEVICE_TARGET is simulator UDID e.g. '12EE4E79-D561-46D2-9F80-BB7278E4A883'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('iPhone 4s', '8.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.udid }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :shared_element
        end

        it "and DEVICE_TARGET is a simulator with a custom name e.g. 'my simulator'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('my simulator', '8.1.2', '12EE4E79-D561-46D2-9F80-BB7278E4A883')
          expect(sim_control).to receive(:simulators).and_return([device])
          launch_args = { :device_target => device.name }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :shared_element
        end
      end

      describe 'Xcode >= 6.0 - DEVICE_TARGET is an iOS >= 8 device' do
        it 'and DEVICE_TARGET is a device UDID' do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('hat', '8.1.2', 'c272271d6efd8ab3d611d52e5511afe75958f90d')
          xcode_tools = sim_control.xctools
          expect(xcode_tools).to receive(:instruments).with(:devices).and_return([device])
          launch_args = { :device_target => device.udid }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :shared_element
        end

        it "and DEVICE_TARGET == 'device'" do
          expect(sim_control).to receive(:xcode_version_gte_6?).at_least(:once).and_return(true)
          device = RunLoop::Device.new('hat', '8.1.2', 'c272271d6efd8ab3d611d52e5511afe75958f90d')
          xcode_tools = sim_control.xctools
          expect(xcode_tools).to receive(:instruments).with(:devices).and_return([device])
          launch_args = { :device_target => 'device' }
          actual = launcher.default_uia_strategy(launch_args, sim_control)
          expect(actual).to be == :shared_element
        end
      end
    end
  end

  describe 'simulator_target? should respond correctly to DEVICE_TARGET' do

    it 'should return true if DEVICE_TARGET is nil' do
      expect(launcher.simulator_target?).to be == false
    end

    it 'should return true if DEVICE_TARGET is simulator' do
      stub_env('DEVICE_TARGET', 'simulator')
      expect(launcher.simulator_target?).to be == true
    end

    it 'should return false if DEVICE_TARGET is device' do
      stub_env('DEVICE_TARGET', 'device')
      expect(launcher.simulator_target?).to be == false
    end

    it 'should return false if DEVICE_TARGET is udid' do
      # noinspection SpellCheckingInspection
      stub_env('DEVICE_TARGET', UDID)
      expect(launcher.simulator_target?).to be == false
    end

    it 'should return true for Xcode 5.1 style simulator names' do
      stub_env('DEVICE_TARGET', 'iPhone Retina (4-inch) - Simulator - iOS 7.1')
      expect(launcher.simulator_target?).to be == true

      stub_env('DEVICE_TARGET', 'iPhone - Simulator - iOS 6.1')
      expect(launcher.simulator_target?).to be == true

      stub_env('DEVICE_TARGET', 'iPad Retina (64-bit) - Simulator - iOS 7.0')
      expect(launcher.simulator_target?).to be == true
    end

    it 'should return true when passed a hash with :device_target => a simulator' do
      hash = {:device_target => 'simulator'}
      expect(launcher.simulator_target?(hash)).to be == true
      hash = {:device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1'}
      expect(launcher.simulator_target?(hash)).to be == true
    end

    it 'should return false when passed a hash with :device_target != a simulator' do
      hash = {:device_target => 'device'}
      expect(launcher.simulator_target?(hash)).to be == false

      hash = {:device_target => UDID}
      expect(launcher.simulator_target?(hash)).to be == false

      hash = {:device_target => 'foobar'}
      expect(launcher.simulator_target?(hash)).to be == false
    end

    it 'should return false when passed a hash with no :device_target key' do
      hash = {:foobar => 'foobar'}
      expect(launcher.simulator_target?(hash)).to be == false
    end
  end

  describe 'resetting application content and settings' do
    describe 'should be able to detect the base simulator sdk from the launch args' do
      it 'should return nil if the test targets a device' do
        expect(launcher).to receive(:device_target?).and_return(true)
        expect(launcher.sdk_version_for_simulator_target({})).to be nil
      end

      it 'should return nil if :device_target is nil' do
        expect(launcher.sdk_version_for_simulator_target({})).to be nil
      end

      it 'should return nil if :device_target is not a simulator' do
        launch_args = {:device_target => UDID}
        expect(launcher.sdk_version_for_simulator_target(launch_args)).to be nil
      end

      it "should return nil if :device_target is 'simulator'" do
        launch_args = {:device_target => 'simulator'}
        expect(launcher.sdk_version_for_simulator_target(launch_args)).to be nil
      end

      it 'should return an SDK if :device_target is an Xcode 5.1+ simulator string' do
        launch_args = {:device_target => 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.0'}
        expect(launcher.sdk_version_for_simulator_target(launch_args)).to be == '7.0'
      end
    end
  end

  describe 'checking server/gem compatibility' do

    before(:example) do
      Calabash::Cucumber::Launcher.class_variable_set(:@@server_version, nil)
    end

    after(:example) do
      Calabash::Cucumber::Launcher.class_variable_set(:@@server_version, nil)
    end

    describe '#server_version_from_server' do

      it 'returns a version by asking the running server' do
        # We can't stand up the server, so we'll create a device and ask for
        # its version.  It is the best we can do for now.
        device = Resources.shared.device_for_mocking
        launcher.device = device
        actual = launcher.server_version_from_server
        expect(actual).not_to be == nil
        expect(RunLoop::Version.new(actual).to_s).to be == '0.10.0'
      end

      it "returns '@@server_version' if it is not nil" do
        Calabash::Cucumber::Launcher.class_variable_set(:@@server_version, '1.0.0')
        actual = launcher.server_version_from_server
        expect(actual).not_to be == nil
        expect(RunLoop::Version.new(actual).to_s).to be == '1.0.0'
      end
    end

    describe '#server_version_from_bundle' do

      describe 'returns calabash version an app bundle when' do
        it 'strings can find the version' do
          abp = Resources.shared.app_bundle_path :server_gem_compatibility
          actual = launcher.server_version_from_bundle abp
          expect(actual).not_to be == nil
          expect(RunLoop::Version.new(actual).to_s).to be == '11.11.11'
        end

        it 'and when there is a space is the path' do
          abp = Resources.shared.app_bundle_path :server_gem_compatibility
          dir = Dir.mktmpdir('path with space')
          FileUtils.cp_r abp, dir
          abp = File.expand_path(File.join(dir, 'server-gem-compatibility.app'))
          actual = launcher.server_version_from_bundle abp
          expect(actual).not_to be == nil
          expect(RunLoop::Version.new(actual).to_s).to be == '11.11.11'
        end
      end

      it "returns '0.0.0' when strings cannot extract a version" do
        abp = Resources.shared.app_bundle_path :chou
        actual = nil
        capture_stderr do
          actual = launcher.server_version_from_bundle abp
        end
        expect(actual).not_to be == nil
        expect(RunLoop::Version.new(actual).to_s).to be == '0.0.0'
      end

      it "returns '@@server_version' if it is not nil" do
        Calabash::Cucumber::Launcher.class_variable_set(:@@server_version, '1.0.0')
        actual = launcher.server_version_from_bundle nil
        expect(actual).not_to be == nil
        expect(RunLoop::Version.new(actual).to_s).to be == '1.0.0'
      end
    end

    describe '#check_server_gem_compatibility' do

      describe 'when targeting an .app' do
        let (:app) { Resources.shared.app_bundle_path :chou }

        describe 'prints a message if server' do
          it 'and gem are compatible' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::MIN_SERVER_VERSION
            expect(launcher).to receive(:server_version_from_bundle).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).to be == ''
          end

          it 'and gem are not compatible' do
            launcher.launch_args = {:app => app}
            min_server_version = '0.0.1'
            expect(launcher).to receive(:server_version_from_bundle).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end

          it 'version cannot be found' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::Launcher::SERVER_VERSION_NOT_AVAILABLE
            expect(launcher).to receive(:server_version_from_bundle).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end
        end
      end

      describe 'when targeting an .ipa' do
        let (:app) { 'foo.ipa' }

        describe 'prints a message if server' do
          it 'and gem are compatible' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::MIN_SERVER_VERSION
            expect(launcher).to receive(:server_version_from_server).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).to be == ''
          end

          it 'and gem are not compatible' do
            launcher.launch_args = {:app => app}
            min_server_version = '0.0.1'
            expect(launcher).to receive(:server_version_from_server).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end

          it 'version cannot be found' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::Launcher::SERVER_VERSION_NOT_AVAILABLE
            expect(launcher).to receive(:server_version_from_server).and_return(min_server_version)
            out = capture_stderr do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end
        end
      end
    end
  end

  describe 'default launch args should respect DEVICE_TARGET' do

    let(:fake_udid) { 'FAKE-UDID' }

    it "should return 'simulator' if DEVICE_TARGET nil" do
      args = launcher.default_launch_args
      expect(args[:device_target]).to be == 'simulator'
    end

    describe 'running with instruments' do

      it 'should be running against instruments' do
        args = launcher.default_launch_args
        expect(args[:launch_method]).to be == :instruments
      end

      describe 'running against devices' do
        describe 'when DEVICE_TARGET = < udid >' do
          it 'it should return udid if DEVICE_TARGET is a udid' do
            stub_env('DEVICE_TARGET', fake_udid)
            args = launcher.default_launch_args
            expect(args[:device_target]).to be == fake_udid
            expect(args[:udid]).to be == fake_udid
          end
        end

        describe 'when DEVICE_TARGET = device' do

          before(:example) do
            stub_env('DEVICE_TARGET', 'device')
          end

          describe 'detecting connected devices' do
            describe "when DETECT_CONNECTED_DEVICE == '1'" do
              it 'should return a udid if DEVICE_TARGET=device if a device is connected and simulator otherwise' do
                stub_env('DETECT_CONNECTED_DEVICE', '1')
                args = launcher.default_launch_args
                target = args[:device_target]
                detected = RunLoop::Core.detect_connected_device

                if detected
                  expect(target).to be == detected
                  expect(args[:udid]).to be == detected
                else
                  #pending('this behavior is needs verification')
                  expect(target).to be == 'simulator'
                end
              end

              context "when DETECT_CONNECTED_DEVICE != '1'" do
                it 'should return a udid if DEVICE_TARGET=device if a device is connected and simulator otherwise' do
                  args = launcher.default_launch_args
                  target = args[:device_target]
                  expect(target).to be == 'device'
                  expect(args[:udid]).to be == 'device'
                end
              end
            end
          end
        end
      end
    end
  end
end

require 'calabash-cucumber/launcher'
require 'calabash-cucumber/utils/simulator_accessibility'

describe 'Calabash Launcher' do

  UDID = '83b59716a3ac25e997770a91477ef4e6ad0ab7bb'

  IPHONE_4IN_R_64 = 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1'

  let (:launcher) { Calabash::Cucumber::Launcher.new }

  let(:simulator) do
    RunLoop::Device.new('iPhone 5s', '8.0', '8612A705-1FC6-4FD8-803D-4F6CB50E1559')
  end

  let(:device) do
    RunLoop::Device.new('pegasi', '8.4', UDID)
  end

  before(:example) {
    RunLoop::SimControl.terminate_all_sims
  }

  describe "#reset_simulator" do
    describe "raises an error when" do
      it "DEVICE_TARGET is a device UDID" do
        stub_env({"DEVICE_TARGET" => UDID})

        expect(launcher.device_target?).to be_truthy
        expect do
          launcher.reset_simulator
        end.to raise_error ArgumentError, /Resetting physical devices is not supported/
      end

      it "device is a RunLoop::Device representing a physical device" do
        expect(launcher).to receive(:device_target?).and_return nil

        expect do
          launcher.reset_simulator(device)
        end.to raise_error ArgumentError, /Resetting physical devices is not supported/
      end
    end

    describe "nil or empty arg" do
      it "DEVICE_TARGET defined" do
        identifier = "simulator"
        expect(Calabash::Cucumber::Environment).to receive(:device_target).and_return(identifier)
        expect(RunLoop::Device).to receive(:device_with_identifier).with(identifier).and_return(simulator)
        expect(RunLoop::CoreSimulator).to receive(:erase).with(simulator).and_return true

        expect(launcher.reset_simulator).to be == simulator
      end

      it "DEVICE_TARGET undefined" do
        identifier = "simulator"
        expect(Calabash::Cucumber::Environment).to receive(:device_target).and_return(nil)
        expect(RunLoop::Core).to receive(:default_simulator).and_return(identifier)
        expect(RunLoop::Device).to receive(:device_with_identifier).with(identifier).and_return(simulator)
        expect(RunLoop::CoreSimulator).to receive(:erase).with(simulator).and_return true

        expect(launcher.reset_simulator).to be == simulator
      end

      it "arg is a device instance" do
        expect(RunLoop::CoreSimulator).to receive(:erase).with(simulator).and_return true

        expect(launcher.reset_simulator(simulator)).to be == simulator
      end

      describe "arg is a string" do
        it "RunLoop cannot find a matching simulator" do
          identifier = "no matching simulator"

          expect do
            launcher.reset_simulator(identifier)
          end.to raise_error ArgumentError, /Could not find a device with a UDID or name matching/
        end

        it "RunLoop can find a matching simulator" do
           identifier = "simulator"
           expect(RunLoop::Device).to receive(:device_with_identifier).with(identifier).and_return(simulator)
           expect(RunLoop::CoreSimulator).to receive(:erase).with(simulator).and_return true

           expect(launcher.reset_simulator(identifier)).to be == simulator
        end
      end
    end
  end

  describe '#discover_device_target' do

    let(:options) do { :device_target => 'OPTION!' } end

    it 'respects the DEVICE_TARGET' do
      stub_env('DEVICE_TARGET', 'TARGET!')

      expect(launcher.discover_device_target(options)).to be == 'TARGET!'
    end

    it 'uses :device_target option' do
      stub_env({'DEVICE_TARGET' => nil})

      expect(launcher.discover_device_target(options)).to be == 'OPTION!'
    end

    it 'returns nil if neither is defined' do
      stub_env({'DEVICE_TARGET' => nil})

      expect(launcher.discover_device_target({})).to be == nil
    end
  end

  describe '.default_uia_strategy' do
    let(:sim_control) { RunLoop::SimControl.new }
    let(:xcode) { sim_control.xcode }
    let(:instruments) { RunLoop::Instruments.new }

    describe 'Xcode >= 7.0' do
      it 'returns :host' do
        expect(sim_control.xcode).to receive(:version_gte_7?).and_return true

        actual = launcher.default_uia_strategy({}, sim_control, instruments)
        expect(actual).to be == :host
      end
    end

    describe 'Xcode < 7.0' do

      before do
        expect(sim_control.xcode).to receive(:version_gte_7?).at_least(:once).and_return false
      end

      it ':device_target is nil' do
        options = { :device_target => nil }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :host
      end

      it ':device_target is the empty string' do
        options = { :device_target => '' }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :host
      end

      it ":device_target is 'simulator'" do
        options = { :device_target => 'simulator' }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :preferences
      end

      it ':device_target is a simulator UDID' do
        expect(sim_control).to receive(:simulators).and_return [simulator]
        options = { :device_target =>  simulator.udid }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :preferences
      end

      it ':device_target is a simulator name' do
        expect(sim_control).to receive(:simulators).and_return [simulator]
        expect(simulator).to receive(:instruments_identifier).and_return 'name'
        options = { :device_target => 'name' }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :preferences
      end

      describe 'physical devices' do

        let(:v71) { RunLoop::Version.new('7.1') }

        before do
          expect(sim_control).to receive(:simulators).and_return []
          expect(instruments).to receive(:physical_devices).and_return [device]
        end

        describe ':device_target is a device UDID' do
          it 'iOS >= 8.0' do
            options = { :device_target => device.udid }

            actual = launcher.default_uia_strategy(options, sim_control, instruments)
            expect(actual).to be == :host
          end

          it 'iOS < 7.0' do
            expect(device).to receive(:version).at_least(:once).and_return v71
            options = { :device_target => device.udid }

            actual = launcher.default_uia_strategy(options, sim_control, instruments)
            expect(actual).to be == :preferences
          end
        end

        describe ':device_target is a device name' do
          it 'iOS >= 8.0' do
            options = { :device_target => device.name }

            actual = launcher.default_uia_strategy(options, sim_control, instruments)
            expect(actual).to be == :host
          end

          it 'iOS < 7.0' do
            expect(device).to receive(:version).at_least(:once).and_return v71
            options = { :device_target => device.name }

            actual = launcher.default_uia_strategy(options, sim_control, instruments)
            expect(actual).to be == :preferences
          end
        end
      end

      it 'returns :host when all else fails' do
        expect(sim_control).to receive(:simulators).and_return []
        expect(instruments).to receive(:physical_devices).and_return []
        options = { :device_target => device.udid }

        actual = launcher.default_uia_strategy(options, sim_control, instruments)
        expect(actual).to be == :host
      end
    end
  end

  describe '#simulator_target?' do

    it ':device_target is nil' do
      options = { :device_target => nil }

      expect(launcher.simulator_target?(options)).to be_falsey
    end

    it ':device_target is the empty string' do
      options = { :device_target => '' }

      expect(launcher.simulator_target?(options)).to be_falsey
    end

    it ":device_target is 'simulator'" do
      options = { :device_target => 'simulator' }

      expect(launcher.simulator_target?(options)).to be_truthy
    end

    it ':device_target is a Xcode 5 Simulator' do
      options = { :device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1' }

      expect(launcher.simulator_target?(options)).to be_truthy
    end

    it ':device_target is a Xcode 6 CoreSimulator' do
      options = { :device_target => 'iPhone 5s (8.4 Simulator)' }

      expect(launcher.simulator_target?(options)).to be_truthy
    end

    it ':device_target is a UDID' do
      options = { :device_target => UDID }

      expect(launcher.simulator_target?(options)).to be_falsey
    end

    it 'not a CoreSimulator environment' do
      expect(launcher.xcode).to receive(:version_gte_6?).and_return false
      options = { :device_target => 'some name' }

      expect(launcher.simulator_target?(options)).to be_falsey
    end

    describe 'CoreSimulator' do

      before do
        expect(launcher.xcode).to receive(:version_gte_6?).at_least(:once).and_return true
      end

      let(:sim_control) { RunLoop::SimControl.new }

      describe 'matches a simulator' do

        let(:options) do { :sim_control => sim_control } end

        before do
          expect(sim_control).to receive(:simulators).and_return [simulator]
        end

        it 'by instruments identifier' do
          # Xcode 7 CoreSimulator - does not contain 'Simulator' in the name.
          expect(simulator).to receive(:instruments_identifier).and_return 'iPhone 5s (9.0)'
          options[:device_target] = 'iPhone 5s (9.0)'

          expect(launcher.simulator_target?(options)).to be_truthy
        end

        it 'by sim udid' do
          options[:device_target] = simulator.udid

          expect(launcher.simulator_target?(options)).to be_truthy
        end
      end

      it 'matches no simulator' do
        expect(sim_control).to receive(:simulators).and_return []
        options = { :device_target => 'some name',
                    :sim_control => sim_control }

        expect(launcher.simulator_target?(options)).to be_falsey
      end
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
        abp = Resources.shared.app_bundle_path :calabash_not_linked
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
        let (:app) { Resources.shared.app_bundle_path :smoke }

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

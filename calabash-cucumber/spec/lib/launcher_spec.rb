require 'calabash-cucumber/launcher'

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

  describe "device attribute" do

    # Legacy API. This is a required method.  Do not remove.
    it "#device=" do
      launcher.device = :device
      expect(launcher.device).to be == :device
      expect(launcher.instance_variable_get(:@device)).to be == :device
    end

    describe "#device" do
      it "is lazy eval'd" do
        launcher.instance_variable_set(:@device, :device)
        expect(launcher.device).to be == :device
      end

      it "calls out to the LPServer" do
        connected = [
          true,
          {"device_name"  => "denis" }
          ]
        expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(connected)
        device = launcher.device

        expect(device).to be_a_kind_of(Calabash::Cucumber::Device)
        expect(device.device_name).to be == "denis"
      end
    end
  end

  it "#usage_tracker" do
    actual = launcher.usage_tracker
    expect(actual).to be_a_kind_of(Calabash::Cucumber::UsageTracker)
    expect(launcher.instance_variable_get(:@usage_tracker)).to be == actual
  end

  describe "#quit_app_after_scenario?" do
    it "#calabash_no_stop?" do
      expect(launcher).to receive(:quit_app_after_scenario?).and_return(false)
      expect(RunLoop).not_to receive(:deprecated).and_call_original
      expect(launcher.calabash_no_stop?).to be_truthy

      expect(launcher).to receive(:quit_app_after_scenario?).and_return(true)
      expect(RunLoop).not_to receive(:deprecated).and_call_original
      expect(launcher.calabash_no_stop?).to be_falsey
    end

    it "calls out to Environment" do
      expect(Calabash::Cucumber::Environment).to receive(:quit_app_after_scenario?).and_return(:value)

      expect(launcher.quit_app_after_scenario?).to be == :value
    end
  end

  describe "#ensure_device_target" do
    it "raises an error" do
      expect(Calabash::Cucumber::Environment).to receive(:device_target).and_return("no matching")

      expect do
        launcher.send(:ensure_device_target)
      end.to raise_error Calabash::Cucumber::DeviceNotFoundError,
                         /Could not find a matching device in your environment/
    end

    it "returns a RunLoop::Device" do
      stub_env({"DEVICE_TARGET" => nil})

      actual = launcher.send(:ensure_device_target)

      expect(actual).to be_a_kind_of(RunLoop::Device)
      expect(actual.simulator?).to be_truthy
    end
  end

  describe "#attach" do
    let(:run_loop) do
      {
        :udid => "identifier",
        :pid => 1
      }
    end

    let(:cache) do
      Class.new do
        def read ; end
      end.new
    end

    before do
      allow(RunLoop::HostCache).to receive(:default).and_return(cache)
      allow(cache).to receive(:read).and_return(run_loop)
    end

    it "the happy path" do
      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(true)

      actual = launcher.attach

      expect(launcher.actions).to be_a_kind_of(Calabash::Cucumber::InstrumentsActions)
      expect(actual).to be == launcher
    end

    it "cannot connect to http server" do
      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_raise(Calabash::Cucumber::ServerNotRespondingError)

      actual = launcher.attach

      expect(launcher.instance_variable_get(:@actions)).to be == nil
      expect(actual).to be_falsey
    end

    it "cannot establish communication with instruments" do
      run_loop[:pid] = nil

      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(true)

      actual = launcher.attach

      expect(launcher.instance_variable_get(:@actions)).to be == nil
      expect(actual).to be == launcher
    end

    it "raises an error on the XTC" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      expect do
        launcher.attach
      end.to raise_error RuntimeError,
        /This method is not available on the Xamarin Test Cloud/
    end
  end

  describe "#reset_simulator" do

    before do
      allow(RunLoop::CoreSimulator).to receive(:erase).and_return(true)
    end

    it "device arg is a RunLoop::Device (simulator)" do
      actual = launcher.reset_simulator(simulator)
      expect(actual).to be == simulator
    end

    it "device arg is a RunLoop::Device (physical device)" do
      expect do
        launcher.reset_simulator(device)
      end.to raise_error ArgumentError, /Resetting physical devices is not supported/
    end

    it "device arg is something else (simulator)" do
      identifier = simulator.udid
      options = { :device => identifier }
      expect(launcher).to receive(:detect_device).with(options).and_return(simulator)
      actual = launcher.reset_simulator(identifier)
      expect(actual).to be == simulator
    end

    it "device arg is something else (physical device)" do
      identifier = device.udid
      options = { :device => identifier }
      expect(launcher).to receive(:detect_device).with(options).and_return(device)
      expect do
        launcher.reset_simulator(identifier)
      end.to raise_error ArgumentError, /Resetting physical devices is not supported/
    end
  end

  it "#discover_device_target - deprecated" do
    expect(launcher.discover_device_target(nil)).to be == nil
  end

  it ".default_uia_strategy - deprecated" do
    expect(launcher.default_uia_strategy(nil, nil, nil)).to be == :host
  end

  it "#simulator_target? - deprecated" do
    expect(launcher.simulator_target?).to be == false
  end

  it "#calabash_no_launch? - deprecated" do
    expect(launcher.calabash_no_stop?).to be == false
  end

  it "#device_target? - deprecated" do
    expect(launcher.device_target?).to be == false
  end

  it "#app_path - deprecated" do
    expect(launcher.app_path).to be == nil
  end

  it "#ensure_connectivity - deprecated" do
    expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(true)
    expect(launcher.ensure_connectivity).to be_truthy
  end

  it "#calabash_notify - deprecated" do
    expect(launcher.calabash_notify(nil)).to be == false
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
        launcher.instance_variable_set(:@device, device)
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
            out = capture_stdout do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end

          it 'version cannot be found' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::Launcher::SERVER_VERSION_NOT_AVAILABLE
            expect(launcher).to receive(:server_version_from_bundle).and_return(min_server_version)
            out = capture_stdout do
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
            out = capture_stdout do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).to be == ''
          end

          it 'and gem are not compatible' do
            launcher.launch_args = {:app => app}
            min_server_version = '0.0.1'
            expect(launcher).to receive(:server_version_from_server).and_return(min_server_version)
            out = capture_stdout do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end

          it 'version cannot be found' do
            launcher.launch_args = {:app => app}
            min_server_version = Calabash::Cucumber::Launcher::SERVER_VERSION_NOT_AVAILABLE
            expect(launcher).to receive(:server_version_from_server).and_return(min_server_version)
            out = capture_stdout do
              launcher.check_server_gem_compatibility
            end
            expect(out.string).not_to be == nil
            expect(out.string.length).not_to be == 0
          end
        end
      end
    end
  end

  it "#default_launch_args - deprecated" do
    expect(launcher.default_launch_args).to be == {}
  end

  it "#detect_connected_device? - deprecated" do
    expect(launcher.detect_connected_device?).to be_falsey
  end

  it "#detect_device" do
    simctl = Resources.shared.sim_control
    xcode = Resources.shared.xcode
    instruments = Resources.shared.instruments
    expect(Calabash::Cucumber::Environment).to receive(:simctl).and_return(simctl)
    expect(Calabash::Cucumber::Environment).to receive(:xcode).and_return(xcode)
    expect(Calabash::Cucumber::Environment).to receive(:instruments).and_return(instruments)

    options = { :device => simulator.udid }
    args = [options, xcode, simctl, instruments]
    expect(RunLoop::Device).to receive(:detect_device).with(*args).and_return(simulator)

    expect(launcher.send(:detect_device, options)).to be == simulator
  end
end

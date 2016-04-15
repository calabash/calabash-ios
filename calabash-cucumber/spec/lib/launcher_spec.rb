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
    expect(launcher).to receive(:detect_device).with({}).and_return(simulator)
    expect(launcher.simulator_target?).to be_truthy

    expect(launcher).to receive(:detect_device).with({}).and_return(device)
    expect(launcher.simulator_target?).to be_falsey
  end

  it "#calabash_no_launch? - deprecated" do
    expect(launcher.calabash_no_stop?).to be == false
  end

  it "#device_target? - deprecated" do
    expect(launcher).to receive(:detect_device).with({}).and_return(simulator)
    expect(launcher.device_target?).to be_falsey

    expect(launcher).to receive(:detect_device).with({}).and_return(device)
    expect(launcher.device_target?).to be_truthy
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

  it "#server_version_from_server - deprecated" do
    expect(launcher).to receive(:server_version).and_return("0.19.0")
    expect(launcher.server_version_from_server).to be == "0.19.0"
  end

  it "#server_version_from_bundle - deprecated" do
    version = RunLoop::Version.new("2.0")
    path = Resources.shared.app_bundle_path(:cal_smoke_app)
    app = RunLoop::App.new(path)

    hash = {
      :app => app,
      :bundle_id => app.bundle_identifier,
      :is_ipa => false
    }
    options = {:app => path }
    expect(RunLoop::DetectAUT).to receive(:detect_app_under_test).with(options).and_return(hash)
    expect(app).to receive(:calabash_server_version).and_return(version)

    expect(launcher.server_version_from_bundle(path)).to be == version
  end

  describe "#check_server_gem_compatibility" do

    let(:cal_device) { Resources.shared.device_for_mocking }
    let(:v20) { RunLoop::Version.new("2.0") }
    let(:v10) { RunLoop::Version.new("1.0") }

    before do
      launcher.instance_variable_set(:@server_version, nil)
      allow(launcher).to receive(:device).and_return(cal_device)
    end

    it "server version is set" do
      expect(launcher).to receive(:server_version).twice.and_return("2.0")

      expect(launcher.check_server_gem_compatibility).to be == "2.0"
    end

    it "compatible" do
      stub_const("Calabash::Cucumber::MIN_SERVER_VERSION", v20.to_s)
      expect(cal_device).to receive(:server_version).and_return(v20.to_s)

      expect(launcher.check_server_gem_compatibility).to be == v20
      expect(launcher.instance_variable_get(:@server_version)).to be == v20
      expect(launcher.send(:server_version)).to be == v20
    end

    it "not compatible" do
      stub_const("Calabash::Cucumber::MIN_SERVER_VERSION", v20.to_s)
      expect(cal_device).to receive(:server_version).and_return(v10.to_s)

      actual = nil

      out = capture_stdout do
        actual = launcher.check_server_gem_compatibility
      end.string

      expect(actual).to be == v10
      expect(launcher.instance_variable_get(:@server_version)).to be == v10
      expect(launcher.send(:server_version)).to be == v10

      match = out[/The server version is not compatible with gem version/, 0]
      expect(match).to be_truthy
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

  describe "#detect_inject_dylib_option" do
    it "options[:inject_dylib] is falsey" do
      expect(launcher.send(:detect_inject_dylib_option, {})).to be == nil
      expect(launcher.send(:detect_inject_dylib_option,
                           {:inject_dylib => false})).to be == nil

      expect(launcher.send(:detect_inject_dylib_option,
                           {:inject_dylib => nil})).to be == nil
    end

    it "{:inject_dylib => true}" do
      expected = Calabash::Cucumber::Dylibs.path_to_sim_dylib
      expect(launcher.send(:detect_inject_dylib_option,
                           {:inject_dylib => true})).to be == expected
    end

    it "{:inject_dylib => 'path/to/dylib'}" do
      expected = "path/to/calabash.dylib"
      expect(launcher.send(:detect_inject_dylib_option,
                           {:inject_dylib => expected})).to be == expected

    end
  end
end

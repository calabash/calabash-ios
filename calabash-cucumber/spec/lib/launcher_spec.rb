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

  let(:instruments_automator) do
    Class.new do
      def run_loop; {:log_file => "path/to/file.log"}; end
      def name; :instruments; end
      def stop; :stopped; end
      def to_s; "#<Instruments RSPEC STUB>"; end
      def inspect; to_s; end
    end.new
  end

  let(:device_agent_automator) do
    Class.new do
      def name; :device_agent; end
      def stop; :stopped; end
      def client
        Class.new do
          def cbx_launcher
            Class.new do
              def name; "iOSDeviceManager"; end
            end.new
          end
          def shutdown; :stopped; end
        end.new
      end
      def to_s; "#<DeviceAgent RSPEC STUB>"; end
      def inspect; to_s; end
    end.new
  end

  let(:unknown_automator) do
    Class.new do
      def name; :automator; end
      def to_s; "#<Automator RSPEC STUB>"; end
      def inspect; to_s; end
    end.new
  end

  context "#to_s" do
    it "is not attached to any automator" do
      expect(launcher.to_s[/not attached to an automator/]).to be_truthy
    end

    it "is attached to instruments" do
      allow(launcher).to receive(:automator).and_return(instruments_automator)

      expect(launcher.to_s[/UIAutomation\/instruments/]).to be_truthy
    end

    it "is attached to device_agent" do
      allow(launcher).to receive(:automator).and_return(device_agent_automator)
      launcher.instance_variable_set(:@automator, device_agent_automator)

      expect(launcher.to_s[/DeviceAgent\/iOSDeviceManager/]).to be_truthy
    end

    it "is attached to some other automator" do
      allow(launcher).to receive(:automator).and_return(unknown_automator)

      expected = "#<Launcher: attached to automator>"
      expect(launcher.to_s).to be == expected
    end

    it "is attached to some automator that does not respond to #name" do
      allow(launcher).to receive(:automator).and_return(unknown_automator)
      expect(unknown_automator).to receive(:respond_to?).with(:name).and_return(false)

      expect(launcher.to_s[/Automator RSPEC STUB/]).to be_truthy
    end
  end

  context "#inspect" do
    it "is the same as to_s" do
      expect(launcher.inspect).to be == launcher.to_s
    end
  end

  context "#stop" do
    it "does nothing if launcher does not have an automator"  do
      allow(launcher).to receive(:automator).and_return(nil)

      expect(launcher.stop).to be == :no_automator
    end

    it "calls RunLoop.stop if automator is :instruments" do
      allow(launcher).to receive(:automator).and_return(instruments_automator)
      expect(launcher.stop).to be == :stopped
    end

    it "calls #stop if automator is :device_agent" do
      allow(launcher).to receive(:automator).and_return(device_agent_automator)

      expect(launcher.stop).to be == :stopped
    end

    it "logs a warning if the automator is unknown" do
      allow(launcher).to receive(:automator).and_return(unknown_automator)

      actual = nil
      out = capture_stdout do
        actual = launcher.stop
      end.string

      expect(actual).to be == :unknown_automator
      expect(out[/Unknown automator/]).to be_truthy
    end

    it "logs a warning if the automator is unknown and does not respond to #name" do
      allow(launcher).to receive(:automator).and_return(unknown_automator)
      expect(unknown_automator).to receive(:respond_to?).with(:name).and_return(false)

      actual = nil
      out = capture_stdout do
        actual = launcher.stop
      end.string

      expect(actual).to be == :unknown_automator
      expect(out[/Unknown automator/]).to be_truthy
    end
  end

  context ".instruments?" do
    it "returns true if @@launcher defined and is attached to :instruments" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return true

      expect(Calabash::Cucumber::Launcher.instruments?).to be_truthy
    end

    it "returns false if @@launcher is not defined" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(nil)

      expect(Calabash::Cucumber::Launcher.instruments?).to be_falsey
    end

    it "returns false if @@launcher is defined, but not attached to :instruments" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return false

      expect(Calabash::Cucumber::Launcher.instruments?).to be_falsey
    end
  end

  context "#instruments?" do
    it "returns true if attached to instruments automator" do
      allow(launcher).to receive(:automator).and_return(instruments_automator)
      expect(launcher).to receive(:attached_to_automator?).and_return(true)

      expect(launcher.instruments?).to be_truthy
    end

    it "returns false if not attached to automator" do
      expect(launcher).to receive(:attached_to_automator?).and_return(false)

      expect(launcher.instruments?).to be_falsey
    end

    it "returns false if attached to automator that is not instruments" do
      allow(launcher).to receive(:automator).and_return(device_agent_automator)
      expect(launcher).to receive(:attached_to_automator?).and_return(true)

      expect(launcher.instruments?).to be_falsey
    end
  end

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
          :pid => 10,
          :udid => "identifier",
          :automator => :instruments,
          :index => 1,
          :log_file => "path/to/log",
          :uia_strategy => :host
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

    it "attaches to an instruments run-loop" do
      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(true)

      actual = launcher.attach

      expect(launcher.automator).to be_a_kind_of(Calabash::Cucumber::Automator::Instruments)
      expect(actual).to be == launcher
    end

    it "raises error if it cannot connect to LPServer" do
      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_raise(Calabash::Cucumber::ServerNotRespondingError)

      actual = launcher.attach

      expect(launcher.instance_variable_get(:@automator)).to be == nil
      expect(actual).to be_falsey
    end

    it "raises if it cannot communication with instruments" do
      run_loop[:pid] = nil

      expect(Calabash::Cucumber::HTTP).to receive(:ensure_connectivity).and_return(true)

      actual = launcher.attach

      expect(launcher.instance_variable_get(:@automator)).to be == nil
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


  it "#calabash_no_launch? - deprecated" do
    expect(launcher.calabash_no_stop?).to be == false
  end

  describe "determining if device is simulator or physical device" do
    let(:cal_device) do
      Class.new do
        def to_s; "#<Calabash::Cucumber::Device>"; end
        def inspect; to_s; end

        def simulator?; ; end
        def device?; ; end
      end.new
    end

    describe "Xamarin Test Cloud" do

      before do
        expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)
      end

      it "#device_target?" do
        expect(launcher.device_target?).to be_truthy
      end

      it "#simulator_target?" do
        expect(launcher.simulator_target?).to be_falsey
      end
    end

    describe "#device_target?" do

      before do
        allow(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)
      end

      it "@device is defined - after app launch check" do
        launcher.instance_variable_set(:@device, cal_device)
        expect(cal_device).to receive(:device?).and_return(true, false)

        expect(launcher.device_target?).to be_truthy
        expect(launcher.device_target?).to be_falsey
      end

      it "@device is not defined - pre launch check" do
        launcher.instance_variable_set(:@device, nil)
        expect(launcher).to receive(:detect_device).with({}).and_return(simulator)
        expect(launcher.device_target?).to be_falsey

        expect(launcher).to receive(:detect_device).with({}).and_return(device)
        expect(launcher.device_target?).to be_truthy
      end
    end

    describe "#simulator_target?" do

      before do
        allow(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)
      end

      it "@device is defined - after launch check" do
        launcher.instance_variable_set(:@device, cal_device)
        expect(cal_device).to receive(:simulator?).and_return(true, false)

        expect(launcher.simulator_target?).to be_truthy
        expect(launcher.simulator_target?).to be_falsey
      end

      it "@device is not defined - pre launch check" do
        launcher.instance_variable_set(:@device, nil)
        expect(launcher).to receive(:detect_device).with({}).and_return(simulator)
        expect(launcher.simulator_target?).to be_truthy

        expect(launcher).to receive(:detect_device).with({}).and_return(device)
        expect(launcher.simulator_target?).to be_falsey
      end
    end
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
    simctl = Resources.shared.simctl
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

  context ".active?" do
    it "is deprecated" do
      expect(RunLoop).to receive(:deprecated).and_call_original
      expect(launcher).to receive(:attached_to_automator?).and_return(:attached)

      expect(launcher.active?).to be == :attached
    end
  end

  context ".attached_to_automator?" do
    it "returns true if #automator is non-nil" do
      launcher.instance_variable_set(:@automator, :automator)
      expect(launcher.attached_to_automator?).to be_truthy
    end

    it "returns false if #automator is nil" do
      launcher.instance_variable_set(:@automator, nil)
      expect(launcher.attached_to_automator?).to be_falsey
    end
  end
end


describe Calabash::Cucumber::Launcher do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:options) do
    {
      :app => Resources.shared.app_bundle_path(:smoke),
      :inject_dylib => true,
      :device_target => "simulator",
      :launch_retries => Luffa::Retry.instance.launch_retries,
      :uia_strategy => :preferences
    }
  end

  before do
    stub_env({"DEBUG" => "1"})
  end

  it "Launch and inject a dylib on a simulator" do
    launcher.relaunch(options)
    expect(launcher.run_loop).not_to be == nil
  end


  it "Raises an error if trying to inject on a device target" do
    options[:device_target] = "83b59716a3ac25e997770a91477ef4e6ad0ab7bb"

    expect do
      launcher.relaunch(options)
    end.to raise_error RuntimeError, /Injecting a dylib is not supported when targetting a device/
  end

  describe "dylibs exist" do
    it "sim dylib" do
      expect(File.exist?(Calabash::Cucumber::Dylibs.path_to_sim_dylib)).to be_truthy
    end

    it "device dylib" do
      expect(File.exist?(Calabash::Cucumber::Dylibs.path_to_device_dylib)).to be_truthy
    end
  end
end


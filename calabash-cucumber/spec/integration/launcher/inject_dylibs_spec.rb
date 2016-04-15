
describe Calabash::Cucumber::Launcher do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:options) do
    {
      :app => Resources.shared.app_bundle_path(:smoke),
      :inject_dylib => true,
      :device_target => "simulator",
      :launch_retries => Luffa::Retry.instance.launch_retries
    }
  end

  before do
    stub_env({"DEBUG" => "1"})
  end

  it "Launch and inject a dylib on a simulator" do
    launcher.relaunch(options)
    expect(launcher.run_loop).not_to be == nil
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


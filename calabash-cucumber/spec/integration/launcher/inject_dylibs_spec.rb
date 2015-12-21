
describe Calabash::Cucumber::Launcher do

  before do
    stub_env({"DEBUG" => "1"})
  end

  it "Launch and inject a dylib on a simulator" do
    launcher = Calabash::Cucumber::Launcher.new

    options = {
      :app => Resources.shared.app_bundle_path(:smoke),
      :inject_dylib => true,
      :device_target => "simulator",
      :launch_retries => Luffa::Retry.instance.launch_retries,
      :uia_strategy => :preferences
    }

    launcher.relaunch(options)
    expect(launcher.run_loop).not_to be == nil
  end
end


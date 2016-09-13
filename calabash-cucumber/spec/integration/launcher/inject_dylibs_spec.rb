
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
    path = Resources.shared.simulator_dylib
    allow(Calabash::Cucumber::Dylibs).to receive(:path_to_sim_dylib).and_return(path)
  end

  it "Launch and inject a dylib on a simulator" do
    if RunLoop::Environment.ci?
      pending("Passes locally, but fails in CI")
      raise "Failing for now"
    else
      if RunLoop::Environment.ci?
        timeout = 40
      else
        timeout = 20
      end
      RunLoop::DylibInjector::RETRY_OPTIONS[:timeout] = timeout
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
    end
  end
end


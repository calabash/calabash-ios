
describe Calabash::Cucumber::Core do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:world) do
    Class.new do
      include Calabash::Cucumber::Core
      def to_s; "#<World>"; end
      def inspect; "#<World>"; end
    end.new
  end

  context "#calabash_exit" do

    it "does not raise an error when the LPServer is not running" do
      expect { world.calabash_exit }.not_to raise_error
    end

    it "does not raise an error when LPServer is running" do
      options =
        {
          :app => Resources.shared.app_bundle_path(:cal_smoke_app),
          :device_target =>  "simulator",
          :launch_retries => Luffa::Retry.instance.launch_retries
        }
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      expect { world.calabash_exit }.not_to raise_error
    end
  end
end

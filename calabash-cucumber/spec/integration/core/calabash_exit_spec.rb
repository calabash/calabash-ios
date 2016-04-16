class CoreIncluded
  include Calabash::Cucumber::Core
end

describe Calabash::Cucumber::Core do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:core_instance) { CoreIncluded.new }

  describe '#calabash_exit' do
    it 'targeting simulators' do
      options =
            {
                  :app => Resources.shared.app_bundle_path(:cal_smoke_app),
                  :device_target =>  'simulator',
                  :launch_retries => Luffa::Retry.instance.launch_retries
            }
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      expect { core_instance.calabash_exit }.not_to raise_error
    end
  end
end

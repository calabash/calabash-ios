class CoreIncluded
  include Calabash::Cucumber::Core
end

describe Calabash::Cucumber::Core do

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
  }

  describe '#calabash_exit' do
    describe 'current Xcode targeting a simulator' do
      it "Xcode #{Resources.shared.current_xcode_version}" do
        sim_control = RunLoop::SimControl.new
        options =
              {
                    :app => Resources.shared.app_bundle_path(:lp_simple_example),
                    :device_target => 'simulator',
                    :sim_control => sim_control,
                    :launch_retries => Resources.shared.travis_ci? ? 5 : 2
              }

        launcher = Calabash::Cucumber::Launcher.new
        launcher.relaunch(options)
        expect(launcher.run_loop).not_to be == nil
        expect { CoreIncluded.new.calabash_exit }.not_to raise_error
      end
    end
  end
end

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
    describe 'targeting simulators' do
      let(:launcher) { Calabash::Cucumber::Launcher.new }
      let(:core_instance) { CoreIncluded.new }
      it "Xcode #{Resources.shared.current_xcode_version}" do
        sim_control = RunLoop::SimControl.new
        options =
              {
                    :app => Resources.shared.app_bundle_path(:lp_simple_example),
                    :device_target => 'simulator',
                    :sim_control => sim_control,
                    :launch_retries => Resources.shared.travis_ci? ? 5 : 2
              }
        launcher.relaunch(options)
        expect(launcher.run_loop).not_to be == nil
        expect { core_instance.calabash_exit }.not_to raise_error
      end

      describe 'Xcode regression' do
        xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
        if xcode_installs.empty?
          it 'no alternative Xcode installs' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            it "Xcode #{version} @ #{path}" do
              ENV['DEVELOPER_DIR'] = path
              sim_control = RunLoop::SimControl.new
              options =
                    {
                          :app => Resources.shared.app_bundle_path(:lp_simple_example),
                          :device_target => 'simulator',
                          :sim_control => sim_control,
                          :launch_retries => Resources.shared.travis_ci? ? 5 : 2
                    }
              launcher.relaunch(options)
              expect(launcher.run_loop).not_to be == nil
              expect { core_instance.calabash_exit }.not_to raise_error
            end
          end
        end
      end
    end
  end
end

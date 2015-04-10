class CoreIncluded
  include Calabash::Cucumber::Core
end

describe Calabash::Cucumber::Core do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:core_instance) { CoreIncluded.new }

  before {
    RunLoop::SimControl.terminate_all_sims
  }

  describe '#calabash_exit' do
    it 'targeting simulators' do
      sim_control = RunLoop::SimControl.new
      sim_control.reset_sim_content_and_settings
      options =
            {
                  :app => Resources.shared.app_bundle_path(:lp_simple_example),
                  :device_target =>  'simulator',
                  :sim_control => sim_control,
                  :launch_retries => Resources.shared.launch_retries
            }
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      expect { core_instance.calabash_exit }.not_to raise_error
    end
  end

  unless Luffa::Environment.travis_ci?
    describe 'targeting physical devices' do
      if !Luffa::IDeviceInstaller.ideviceinstaller_available?
        it 'device testing requires ideviceinstaller to be available in the PATH' do
          expect(true).to be == true
        end
      else
        sim_control = RunLoop::SimControl.new
        xcode_tools = sim_control.xctools
        xcode_version = xcode_tools.xcode_version

        physical_devices = Resources.shared.physical_devices_for_testing(xcode_tools)
        if physical_devices.empty?
          it 'no physical devices available' do expect(true).to be_truthy end
        else
          physical_devices.each do |device|
            if Luffa::Xcode::ios_version_incompatible_with_xcode_version?(device.version, xcode_version)
              it "Skipping #{device.name} iOS #{device.version} with Xcode #{xcode_version} - combination not supported" do
                expect(true).to be == true
              end
            else
              it "on #{device.name} iOS #{device.version} Xcode #{xcode_version}" do
                stub_env('DEVICE_ENDPOINT', "http://#{device.name}.local:37265")

                options =
                          {
                                :bundle_id => Resources.shared.bundle_id,
                                :udid => device.udid,
                                :device_target => device.udid,
                                :sim_control => sim_control,
                                :launch_retries => Resources.shared.launch_retries
                          }

                expect {
                  Resources.shared.ideviceinstaller.install(device.udid)
                }.to_not raise_error

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
end

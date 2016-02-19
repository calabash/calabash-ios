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
                  :app => Resources.shared.app_bundle_path(:cal_smoke_app),
                  :device_target =>  'simulator',
                  :sim_control => sim_control,
                  :launch_retries => Luffa::Retry.instance.launch_retries
            }
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      expect { core_instance.calabash_exit }.not_to raise_error
    end

    unless Luffa::Environment.travis_ci? &&
          Luffa::IDeviceInstaller.ideviceinstaller_available? &&
          !Resources.shared.physical_devices_for_testing(RunLoop::Instruments.new).empty?

      describe 'targeting physical devices' do
        sim_control = RunLoop::SimControl.new
        xcode = sim_control.xcode
        xcode_version = xcode.version
        instruments = RunLoop::Instruments.new
        Resources.shared.physical_devices_for_testing(instruments).each do |device|
          if Luffa::Xcode::ios_version_incompatible_with_xcode_version?(device.version, xcode_version)
            it "Skipping #{device.name} iOS #{device.version} with Xcode #{xcode} - combination not supported" do
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
                          :launch_retries => Luffa::Retry.instance.launch_retries
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

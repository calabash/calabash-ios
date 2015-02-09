class CoreIncluded
  include Calabash::Cucumber::Core
  include Calabash::Cucumber::KeyboardHelpers
  include Calabash::Cucumber::WaitHelpers
end

describe Calabash::Cucumber::UIA do

  describe 'targeting simulators' do
    let(:launcher) { Calabash::Cucumber::Launcher.new }
    let(:core_instance) { CoreIncluded.new }
    let(:options) {
      options =
            {
                  :app => Resources.shared.app_bundle_path(:lp_simple_example),
                  :device_target =>  'simulator',
                  :sim_control => RunLoop::SimControl.new,
                  :launch_retries => Resources.shared.launch_retries
            }
    }

    it "Xcode #{Resources.shared.current_xcode_version} strategy :preferences" do
      options[:uia_strategy] = :preferences
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      core_instance.wait_tap('textField')
      core_instance.wait_for_keyboard
    end

    it "Xcode #{Resources.shared.current_xcode_version} strategy :shared_element" do
      options[:uia_strategy] = :shared_element
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      core_instance.wait_tap('textField')
      core_instance.wait_for_keyboard
    end

    it "Xcode #{Resources.shared.current_xcode_version} strategy :host" do
      options[:uia_strategy] = :host
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil
      expect { core_instance.wait_tap('textField') }.to raise_error RuntimeError
    end
  end
end

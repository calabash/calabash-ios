describe Calabash::Cucumber::Device do

  before do
    RunLoop::SimControl.terminate_all_sims
    RunLoop::SimControl.new.reset_sim_content_and_settings
  end

  let(:endpoint) { 'http://localhost:37265' }

  describe '#form_factor' do
    let(:device)  do
      options = {
            :app => Resources.shared.app_bundle_path(:lp_simple_example),
            :device_target =>  device_target,
            :sim_control => RunLoop::SimControl.new,
            :launch_retries => Luffa::Retry.instance.launch_retries
      }
      launcher = Calabash::Cucumber::Launcher.new
      launcher.relaunch(options)
      launcher.device
    end

    subject { device.form_factor }

    context 'device is an ipad' do
      let(:device_target) {
        xcode_tools = RunLoop::XCTools.new
        version = xcode_tools.xcode_version
        if xcode_tools.xcode_version_gte_6?
          Luffa::Simulator.instance.core_simulator_for_xcode_version('iPad', 'Retina', version)
        else
          'iPad Retina (64-bit) - Simulator - iOS 7.1'
        end
      }
      it { is_expected.to be == 'ipad' }
    end

    context 'device is an 4in iphone' do
      let(:device_target) {
        xcode_tools = RunLoop::XCTools.new
        version = xcode_tools.xcode_version
        if xcode_tools.xcode_version_gte_6?
          Luffa::Simulator.instance.core_simulator_for_xcode_version('iPhone', '5', version)
        else
          'iPhone Retina (4-inch) - Simulator - iOS 7.1'
        end
      }
      it { is_expected.to be == 'iphone 4in' }
    end

    context 'device is a 3.5" iphone' do
      let(:device_target) {
        xcode_tools = RunLoop::XCTools.new
        version = xcode_tools.xcode_version
        if xcode_tools.xcode_version_gte_6?
          Luffa::Simulator.instance.core_simulator_for_xcode_version('iPhone', '4s', version)
        else
          'iPhone Retina (3.5-inch) - Simulator - iOS 7.1'
        end
      }
      it { is_expected.to be == 'iphone 3.5in' }
    end

    context 'device is an iphone 6' do
      let(:device_target) {
        xcode_tools = RunLoop::XCTools.new
        version = xcode_tools.xcode_version
        if xcode_tools.xcode_version_gte_6?
          Luffa::Simulator.instance.core_simulator_for_xcode_version('iPhone', '6', version)
        else
          # iPhone 6 does not exist on Xcode < 6
          nil
        end
      }
      it { is_expected.to be == 'iphone 6' if device_target }
    end

    context 'device is an iphone 6+' do
      let(:device_target) {
        xcode_tools = RunLoop::XCTools.new
        version = xcode_tools.xcode_version
        if xcode_tools.xcode_version_gte_6?
          Luffa::Simulator.instance.core_simulator_for_xcode_version('iPhone', '6 Plus', version)
        else
          # iPhone 6 does not exist on Xcode < 6
          nil
        end
      }
      it { is_expected.to be == 'iphone 6+' if device_target }
    end
  end
end

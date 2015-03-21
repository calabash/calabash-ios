describe Calabash::Cucumber::Device do

  before(:example) do
    RunLoop::SimControl.terminate_all_sims
  end

  after(:example) {
    RunLoop::SimControl.terminate_all_sims
  }

  let(:endpoint) { 'http://localhost:37265' }

  describe '#form_factor' do
    let(:device)  do
      options = {
            :app => Resources.shared.app_bundle_path(:lp_simple_example),
            :device_target =>  device_target,
            :sim_control => RunLoop::SimControl.new,
            :launch_retries => Resources.shared.launch_retries
      }
      launcher = Calabash::Cucumber::Launcher.new
      launcher.relaunch(options)
      launcher.device
    end

    describe 'regression on simulators' do
      xcode_installs = Resources.shared.supported_xcode_version_paths
      if xcode_installs.empty?
        it 'no alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        subject { device.form_factor }
        xcode_installs.each do |developer_dir|
          context "#{developer_dir}" do
            before do
              stub_env('DEVELOPER_DIR', developer_dir)
            end

            context 'device is an ipad' do
              let(:device_target) {
                xcode_tools = RunLoop::XCTools.new
                version = xcode_tools.xcode_version
                if xcode_tools.xcode_version_gte_6?
                  Resources.shared.core_simulator_for_xcode_version('iPad', 'Retina', version)
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
                  Resources.shared.core_simulator_for_xcode_version('iPhone', '5', version)
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
                  Resources.shared.core_simulator_for_xcode_version('iPhone', '4s', version)
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
                  Resources.shared.core_simulator_for_xcode_version('iPhone', '6', version)
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
                  Resources.shared.core_simulator_for_xcode_version('iPhone', '6 Plus', version)
                else
                  # iPhone 6 does not exist on Xcode < 6
                  nil
                end
              }
              it { is_expected.to be == 'iphone 6+' if device_target }
            end
          end
        end
      end
    end
  end
end

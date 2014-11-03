describe Calabash::Cucumber::Device do

  before(:each) do
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEBUG_UNIX_CALLS')
    RunLoop::SimControl.terminate_all_sims
  end

  after(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEBUG_UNIX_CALLS')
    RunLoop::SimControl.terminate_all_sims
  }

  # noinspection RubyStringKeysInHashInspection
  let(:simulator_data) { Resources.shared.server_version :simulator }
  let(:endpoint) { 'http://localhost:37265' }

  describe '#ios8?' do
    it 'returns false when target is not iOS 8' do
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      expect(device.ios8?).to be == false
    end

    it 'returns true when target is iOS 8' do
      simulator_data['iOS_version'] = '8.0'
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      expect(device.ios8?).to be == true
    end
  end

  describe '#iphone_4in?' do
    let(:device)  do
      options = {
            :app => Resources.shared.app_bundle_path(:lp_simple_example),
            :device_target =>  device_target,
            :sim_control => RunLoop::SimControl.new,
            :launch_retries => Resources.shared.travis_ci? ? 5 : 2
      }
      launcher = Calabash::Cucumber::Launcher.new
      launcher.relaunch(options)
      launcher.device
    end

    describe 'regression' do
      xcode_installs = Resources.shared.supported_xcode_version_paths
      if xcode_installs.empty?
        it 'no alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        subject { device.iphone_4in? }
        xcode_installs.each do |developer_dir|
          context "#{developer_dir}" do
            before do
              ENV['DEVELOPER_DIR'] = developer_dir
            end

            context 'device is an 4in iphone' do
              let(:device_target) {
                xcode_tools = RunLoop::XCTools.new
                if xcode_tools.xcode_version_gte_61?
                  'iPhone 5 (8.1 Simulator)'
                elsif xcode_tools.xcode_version_gte_6?
                  'iPhone 5 (8.0 Simulator)'
                else
                  'iPhone Retina (4-inch) - Simulator - iOS 7.1'
                end
              }
              it { should be == true }
            end
            context 'device is a 3.5" iphone' do
              let(:device_target) {
                xcode_tools = RunLoop::XCTools.new
                if xcode_tools.xcode_version_gte_61?
                  'iPhone 4s (8.1 Simulator)'
                elsif xcode_tools.xcode_version_gte_6?
                  'iPhone 4s (8.0 Simulator)'
                else
                  'iPhone Retina (3.5-inch) - Simulator - iOS 7.1'
                end
              }
              it { should be == false }
            end
            context 'device is an iphone 6' do
              let(:device_target) {
                xcode_tools = RunLoop::XCTools.new
                if xcode_tools.xcode_version_gte_61?
                  'iPhone 6 (8.1 Simulator)'
                elsif xcode_tools.xcode_version_gte_6?
                  'iPhone 6 (8.0 Simulator)'
                else
                  # iPhone 6 does not exist on Xcode < 6
                  nil
                end
              }
              it { should be == false if device_target }
            end
            context 'device is an iphone 6+' do
              let(:device_target) {
                xcode_tools = RunLoop::XCTools.new
                if xcode_tools.xcode_version_gte_61?
                  'iPhone 6 Plus (8.1 Simulator)'
                elsif xcode_tools.xcode_version_gte_6?
                  'iPhone 6 Plus (8.0 Simulator)'
                else
                  # iPhone 6 does not exist on Xcode < 6
                  nil
                end
              }
              it { should be == false if device_target }
            end
          end
        end
      end
    end
  end
end

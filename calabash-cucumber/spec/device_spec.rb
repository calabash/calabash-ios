describe Calabash::Cucumber::Device do

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
      sim_control = RunLoop::SimControl.new
      options = {
        :app => Resources.shared.app_bundle_path(:lp_simple_example),
        :device_target =>  device_target,
        :sim_control => sim_control,
        :launch_retries => Resources.shared.travis_ci? ? 5 : 2
      }
      launcher = Calabash::Cucumber::Launcher.new
      launcher.relaunch(options)
      launcher.device
    end

    subject { device.iphone_4in? }
    context 'device is an 4in iphone' do
      let(:device_target) { 'iPhone 5 (8.1 Simulator)' }
      it { should be == true }
    end
    context 'device is a 3.5" iphone' do
      let(:device_target) { 'iPhone 4s (8.1 Simulator)' }
      it { should be == false }
    end
    context 'device is an iphone 6' do
      let(:device_target) { 'iPhone 6 (8.1 Simulator)' }
      it { should be == false }
    end
    context 'device is an iphone 6+' do
      let(:device_target) { 'iPhone 6 Plus (8.1 Simulator)' }
      it { should be == false }
    end
  end
end

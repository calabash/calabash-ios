describe Calabash::Cucumber::Device do

  # noinspection RubyStringKeysInHashInspection
  let(:simulator_data) {
    {
          'app_version' => '1.0',
          'outcome' => 'SUCCESS',
          'app_id' => 'com.xamarin.chou-cal',
          'simulator_device' => 'iPhone',
          'version' => '0.11.0',
          'app_name' => 'chou-cal',
          'iphone_app_emulated_on_ipad' => false,
          '4inch' => true,
          'git' => {
                'remote_origin' => 'git@github.com:calabash/calabash-ios-server.git',
                'branch' => 'develop',
                'revision' => '652b20b'
          },
          'screen_dimensions' => {
                'scale' => 2,
                'width' => 640,
                'sample' => 1,
                'height' => 1136
          },
          'iOS_version' => '7.1',
          'system' => 'x86_64',
          'simulator' => 'CoreSimulator 110.2 - Device: iPhone 5 - Runtime: iOS 7.1 (11D167) - DeviceType: iPhone 5'
    }
  }

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

end

describe Calabash::Cucumber::Device do

  let(:simulator_data) { Resources.shared.server_version :simulator }
  let(:endpoint) { 'http://localhost:37265' }

  describe '#ios9?' do
    it 'returns false when target is not iOS 9' do
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)

      expect(device.ios9?).to be == false
    end

    it 'returns true when target is iOS 9' do
      simulator_data['iOS_version'] = '9.0'
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)

      expect(device.ios9?).to be == true
    end
  end

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

  it '#form_factor' do
    version_data = Resources.shared.server_version(:simulator)
    device = Calabash::Cucumber::Device.new(double('end_point'), version_data)
    expect(device.form_factor).to be == 'iphone 4in'
  end

  describe 'form_factor query methods' do
    let(:device) {
      version_data = Resources.shared.server_version(:simulator)
      Calabash::Cucumber::Device.new(double('end_point'), version_data)
    }

    describe '#iphone_6?' do
      it "is true when form factor is 'iphone 6'" do
        expect(device).to receive(:form_factor).and_return('iphone 6')
        expect(device.iphone_6?).to be == true
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')
        expect(device.iphone_6?).to be == false
      end
    end

    describe '#iphone_6_plus?' do
      it "is true when form factor is 'iphone 6+'" do
        expect(device).to receive(:form_factor).and_return('iphone 6+')
        expect(device.iphone_6_plus?).to be == true
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')
        expect(device.iphone_6_plus?).to be == false
      end
    end

    describe '#iphone_35in?' do
      it "is true when form factor is 'iphone 3.5in'" do
        expect(device).to receive(:form_factor).and_return('iphone 3.5in')
        expect(device.iphone_35in?).to be == true
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')
        expect(device.iphone_35in?).to be == false
      end
    end

    describe '#iphone_4in?' do
      it "is true when form factor is 'iphone 4in'" do
        expect(device).to receive(:form_factor).and_return('iphone 4in')
        expect(device.iphone_4in?).to be == true
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')
        expect(device.iphone_4in?).to be == false
      end
    end
  end
end

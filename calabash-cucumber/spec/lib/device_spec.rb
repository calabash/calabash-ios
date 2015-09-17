describe Calabash::Cucumber::Device do

  let(:endpoint) { 'http://localhost:37265' }

  let(:version_data) { {'system' => ''} }

  let(:device_factory) do
    lambda do |data|
      Calabash::Cucumber::Device.new(endpoint, data)
    end
  end

  let(:device) { device_factory.call(version_data) }

  describe 'iOS version' do
    let(:nine) { RunLoop::Version.new('9.0') }
    let(:eight) { RunLoop::Version.new('8.0') }
    let(:seven) { RunLoop::Version.new('7.0') }

    it '#ios9?' do
      expect(device).to receive(:ios_version_object).and_return(nine, eight)

      expect(device.ios9?).to be_truthy
      expect(device.ios9?).to be_falsey
    end

    it '#ios8?' do
      expect(device).to receive(:ios_version_object).and_return(eight, seven)

      expect(device.ios8?).to be_truthy
      expect(device.ios8?).to be_falsey
    end

    it '#ios7?' do
      expect(device).to receive(:ios_version_object).and_return(seven, eight)

      expect(device.ios7?).to be_truthy
      expect(device.ios7?).to be_falsey
    end

    it '#ios_major_version' do
      expect(device).to receive(:ios_version_object).and_return(nine)

      expect(device.ios_major_version).to be == '9'
    end
  end


  it '#form_factor' do
    version_data['form_factor'] = 'iphone 4in'
    device = device_factory.call(version_data)

    expect(device.form_factor).to be == 'iphone 4in'
  end

  describe 'form_factor query methods' do

    describe '#iphone_6?' do
      it "is true when form factor is 'iphone 6'" do
        expect(device).to receive(:form_factor).and_return('iphone 6')

        expect(device.iphone_6?).to be_truthy
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')

        expect(device.iphone_6?).to be_falsey
      end
    end

    describe '#iphone_6_plus?' do
      it "is true when form factor is 'iphone 6+'" do
        expect(device).to receive(:form_factor).and_return('iphone 6+')

        expect(device.iphone_6_plus?).to be_truthy
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')

        expect(device.iphone_6_plus?).to be_falsey
      end
    end

    describe '#iphone_35in?' do
      it "is true when form factor is 'iphone 3.5in'" do
        expect(device).to receive(:form_factor).and_return('iphone 3.5in')

        expect(device.iphone_35in?).to be_truthy
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')

        expect(device.iphone_35in?).to be_falsey
      end
    end

    describe '#iphone_4in?' do
      it "is true when form factor is 'iphone 4in'" do
        expect(device).to receive(:form_factor).and_return('iphone 4in')

        expect(device.iphone_4in?).to be_truthy
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')

        expect(device.iphone_4in?).to be_falsey
      end
    end

    describe '#ipad_pro?' do
      it 'is true when form factor is ipad pro' do
        expect(device).to receive(:form_factor).and_return('ipad pro')

        expect(device.ipad_pro?).to be_truthy
      end

      it 'is false otherwise' do
        expect(device).to receive(:form_factor).and_return('any other value')

        expect(device.ipad_pro?).to be_falsey
      end
    end
  end
end

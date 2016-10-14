describe Calabash::Cucumber::Device do

  let(:endpoint) { 'http://localhost:37265' }

  let(:version_data) { {'system' => ''} }

  let(:device_factory) do
    lambda do |data|
      Calabash::Cucumber::Device.new(endpoint, data)
    end
  end

  let(:device) { device_factory.call(version_data) }

  describe '.new' do
    it 'sets @model_identifier' do
      version_data['model_identifier'] = 'iPhone11,11'

      expect(device.model_identifier).to be == 'iPhone11,11'
      expect(device.instance_variable_get(:@model_identifier)).to be == 'iPhone11,11'
    end

    it 'sets @device_name' do
      version_data['device_name'] = 'whale'

      expect(device.device_name).to be == 'whale'
      expect(device.instance_variable_get(:@device_name)).to be == 'whale'
    end

    it 'sets @endpoint' do
      expect(device.endpoint).to be == endpoint
      expect(device.instance_variable_get(:@endpoint)).to be == endpoint
    end

    describe 'sets @ios_version' do
      it "uses 'ios_version' when available" do
        version_data['ios_version'] = 'this one'
        version_data['iOS_version'] = 'deprecated'

        expect(device.ios_version).to be == 'this one'
        expect(device.instance_variable_get(:@ios_version)).to be == 'this one'
      end

      it "uses 'iOS_version' when 'ios_version' not available" do
        version_data['iOS_version'] = 'deprecated'

        expect(device.ios_version).to be == 'deprecated'
        expect(device.instance_variable_get(:@ios_version)).to be == 'deprecated'
      end
    end

    it 'sets @server_version' do
      version_data['version'] = 'server version'

      expect(device.server_version).to be == 'server version'
      expect(device.instance_variable_get(:@server_version)).to be == 'server version'
    end

    it 'sets @iphone_app_emulated_on_ipad' do
      version_data['iphone_app_emulated_on_ipad'] = 'emulated'

      expect(device.instance_variable_get(:@iphone_app_emulated_on_ipad)).to be == 'emulated'
      expect(device.iphone_app_emulated_on_ipad?).to be_truthy
    end

    it 'sets @form_factor' do
      version_data['form_factor'] = 'form'

      expect(device.form_factor).to be == 'form'
      expect(device.instance_variable_get(:@form_factor)).to be == 'form'
    end

    describe 'sets @device_family' do
      it "uses 'device_family' if it is available" do
        version_data['device_family'] = 'first element only'
        version_data['system'] = 'deprecated'

        expect(device.device_family).to be == 'first'
        expect(device.instance_variable_get(:@device_family)).to be == 'first'
      end
    end

    it 'sets @simulator_details' do
      version_data['simulator'] = 'Core Simulator'

      expect(device.simulator_details).to be == 'Core Simulator'
      expect(device.instance_variable_get(:@simulator_details)).to be == 'Core Simulator'
    end

    describe 'sets @screen_dimensions' do
      it 'converts to a symbol key/value pairs' do
        version_data['screen_dimensions'] = { 'a' => 1, 'b' => 2 }

        expected = {:a => 1, :b => 2}

        expect(device.screen_dimensions).to be == expected
        expect(device.instance_variable_get(:@screen_dimensions)).to be == expected
      end

      it "does nothing if 'screen_dimensions' is not available" do
        version_data['screen_dimensions'] = nil

        expect(device.screen_dimensions).to be == nil
        expect(device.instance_variable_get(:@screen_dimensions)).to be == nil
      end
    end
  end

  describe "#simulator?" do
    it "returns true" do
      expect(device).to receive(:simulator_details).and_return("Core Simulator")

      expect(device.simulator?).to be_truthy
    end

    describe "returns false" do
      it "simulator_details are nil" do
        expect(device).to receive(:simulator_details).and_return(nil)

        expect(device.simulator?).to be_falsey
      end

      it "simulator_details are the empty string" do
        expect(device).to receive(:simulator_details).and_return("")

        expect(device.simulator?).to be_falsey
      end
    end

  end

  describe 'iOS version' do
    let(:ten) { RunLoop::Version.new("10.0") }
    let(:nine) { RunLoop::Version.new('9.0') }
    let(:eight) { RunLoop::Version.new('8.0') }
    let(:seven) { RunLoop::Version.new('7.0') }

    it "#ios10?" do
      expect(device).to receive(:ios_version_object).and_return(ten, nine)

      expect(device.ios10?).to be_truthy
      expect(device.ios10?).to be_falsey
    end

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

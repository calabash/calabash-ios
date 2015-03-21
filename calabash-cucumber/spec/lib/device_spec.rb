describe Calabash::Cucumber::Device do

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
    let(:device) { Calabash::Cucumber::Device.new(double('end_point'), version_data) }
    subject { device.iphone_4in? }
    context 'when server says it is 4"' do
      let(:version_data) { Resources.shared.server_version(:simulator).merge({'4inch' => true}) }
      it { is_expected.to be_truthy }
    end
    context 'when server says it is not 4"' do
      let(:version_data) { Resources.shared.server_version(:simulator).merge({'4inch' => false}) }
      it { is_expected.not_to be_truthy }
    end
  end

  it '#form_factor' do
    version_data = Resources.shared.server_version(:simulator)
    device = Calabash::Cucumber::Device.new(double('end_point'), version_data)
    expect(device.form_factor).to be == 'iphone 4in'
  end

end

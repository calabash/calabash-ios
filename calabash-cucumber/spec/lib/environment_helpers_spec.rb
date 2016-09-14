describe Calabash::Cucumber::EnvironmentHelpers do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::EnvironmentHelpers
    end.new
  end

  let(:endpoint) { 'http://localhost:37265' }
  let(:version_data) { {'system' => ''} }
  let(:device) { Calabash::Cucumber::Device.new(endpoint, version_data) }

  before do
    expect(world).to receive(:default_device).at_least(:once).and_return device
  end

  it '.ios_version' do
    expected = RunLoop::Version.new('9.0')
    expect(device).to receive(:ios_version).and_return('9.0')

    expect(world.ios_version).to be == expected
  end

  it '.ios8?' do
    expect(device).to receive(:ios8?).and_return(true, false)

    expect(world.ios8?).to be_truthy
    expect(world.ios8?).to be_falsey
  end

  it '.ios9?' do
    expect(device).to receive(:ios9?).and_return(true, false)

    expect(world.ios9?).to be_truthy
    expect(world.ios9?).to be_falsey
  end

  it '.ios9?' do
    expect(device).to receive(:ios10?).and_return(true, false)

    expect(world.ios10?).to be_truthy
    expect(world.ios10?).to be_falsey
  end

  describe 'form factor helpers' do
    it '.iphone_35in?' do
      expect(device).to receive(:iphone_35in?).and_return(true, false)

      expect(world.iphone_35in?).to be_truthy
      expect(world.iphone_35in?).to be_falsey
    end

    it '.iphone_4in?' do
      expect(device).to receive(:iphone_4in?).and_return(true, false)

      expect(world.iphone_4in?).to be_truthy
      expect(world.iphone_4in?).to be_falsey
    end

    it '.iphone_6?' do
      expect(device).to receive(:iphone_6?).and_return(true, false)

      expect(world.iphone_6?).to be_truthy
      expect(world.iphone_6?).to be_falsey
    end

    it '.iphone_6_plus?' do
      expect(device).to receive(:iphone_6_plus?).and_return(true, false)

      expect(world.iphone_6_plus?).to be_truthy
      expect(world.iphone_6_plus?).to be_falsey
    end

    it '.ipad_pro?' do
      expect(device).to receive(:ipad_pro?).and_return(true, false)

      expect(world.ipad_pro?).to be_truthy
      expect(world.ipad_pro?).to be_falsey
    end
  end

  it '.screen_dimensions' do
    expect(device).to receive(:screen_dimensions).and_return({:a => 1})

    expect(world.screen_dimensions).to be == {:a => 1}
  end
end

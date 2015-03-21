module Calabash
  module RspecTests
    module EnvironmentHelpers
      class TestObject
        include Calabash::Cucumber::EnvironmentHelpers
      end
    end
  end
end

describe Calabash::Cucumber::EnvironmentHelpers do

  let(:endpoint) { 'http://localhost:37265' }
  let(:test_obj) { Calabash::RspecTests::EnvironmentHelpers::TestObject.new }

  describe '.ios8?' do
    let(:simulator_data) { Resources.shared.server_version :simulator }

    it 'returns true when device under test is iOS 8' do
      simulator_data['iOS_version'] = '8.0'
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      expect(test_obj).to receive(:default_device).and_return(device)
      expect(test_obj.ios8?).to be == true
    end

    it 'returns false when device under test is not iOS 8' do
      simulator_data['iOS_version'] = '7.0'
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      expect(test_obj).to receive(:default_device).and_return(device)
      expect(test_obj.ios8?).to be == false
    end
  end

  describe 'form factor helpers' do
    let(:device) {
      simulator_data = Resources.shared.server_version :simulator
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      expect(test_obj).to receive(:default_device).and_return(device)
      device
    }

    describe '.iphone_35in?' do
      it 'returns true' do
        expect(device).to receive(:iphone_35in?).and_return(true)
        expect(test_obj.iphone_35in?).to be == true
      end

      it 'returns false' do
        expect(device).to receive(:iphone_35in?).and_return(false)
        expect(test_obj.iphone_35in?).to be == false
      end
    end

    describe '.iphone_4in?' do
      it 'returns true' do
        expect(device).to receive(:iphone_4in?).and_return(true)
        expect(test_obj.iphone_4in?).to be == true
      end

      it 'returns false' do
        expect(device).to receive(:iphone_4in?).and_return(false)
        expect(test_obj.iphone_4in?).to be == false
      end
    end

    describe '.iphone_6?' do
      it 'returns true' do
        expect(device).to receive(:iphone_6?).and_return(true)
        expect(test_obj.iphone_6?).to be == true
      end

      it 'returns false' do
        expect(device).to receive(:iphone_6?).and_return(false)
        expect(test_obj.iphone_6?).to be == false
      end
    end

    describe '.iphone_6_plus?' do
      it 'returns true' do
        expect(device).to receive(:iphone_6_plus?).and_return(true)
        expect(test_obj.iphone_6_plus?).to be == true
      end

      it 'returns false' do
        expect(device).to receive(:iphone_6_plus?).and_return(false)
        expect(test_obj.iphone_6_plus?).to be == false
      end
    end
  end
end

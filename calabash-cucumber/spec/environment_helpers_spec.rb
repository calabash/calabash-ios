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

  let(:simulator_data) { Resources.shared.server_version :simulator }
  let(:endpoint) { 'http://localhost:37265' }
  let(:test_obj) { Calabash::RspecTests::EnvironmentHelpers::TestObject.new }

  describe 'ios8?' do
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
end

require 'spec_helper'
require 'calabash-cucumber/launcher'

describe 'Calabash Launcher' do

  before(:each) do
    @launcher = Calabash::Cucumber::Launcher.new
  end

  describe 'simulator_target? should respond correctly to DEVICE_TARGET' do

    before(:each) do
      ENV['DEVICE_TARGET'] = ''
    end

    def set_device_target(val)
      ENV['DEVICE_TARGET'] = val
    end

    it 'should return true if DEVICE_TARGET is simulator' do
      set_device_target('simulator')
      expect(@launcher.simulator_target?).to be == true
    end

    it 'should return false if DEVICE_TARGET is device' do
      set_device_target('device')
      expect(@launcher.simulator_target?).to be == false
    end

    it 'should return false if DEVICE_TARGET is udid' do
      # noinspection SpellCheckingInspection
      set_device_target('66h3hfgc466836ehcg72738eh8f322842855d2fd')
      expect(@launcher.simulator_target?).to be == false
    end

    it 'should return true for Xcode 5.1 style simulator names' do
      set_device_target('iPhone Retina (4-inch) - Simulator - iOS 7.1')
      expect(@launcher.simulator_target?).to be == true

      set_device_target('iPhone - Simulator - iOS 6.1')
      expect(@launcher.simulator_target?).to be == true

      set_device_target('iPad Retina (64-bit) - Simulator - iOS 7.0')
      expect(@launcher.simulator_target?).to be == true
    end

    it 'should return true when passed a hash with :device_target => a simulator' do
      hash = {:device_target => 'simulator'}
      expect(@launcher.simulator_target?(hash)).to be == true

      hash = {:device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1'}
      expect(@launcher.simulator_target?(hash)).to be == true
    end

    it 'should return false when passed a hash with :device_target != a simulator' do
      hash = {:device_target => 'device'}
      expect(@launcher.simulator_target?(hash)).to be == false

      hash = {:device_target => '66h3hfgc466836ehcg72738eh8f322842855d2fd'}
      expect(@launcher.simulator_target?(hash)).to be == false
    end

  end
end
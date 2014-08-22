require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/launcher'
require 'sim_launcher'

include Calabash::Cucumber::SimulatorAccessibility

describe 'simulator accessibility tool' do

  it 'should be able to find the simulator app support directory' do
    path = simulator_app_support_dir
    expect(File.exist?(path)).to be == true
  end

  it 'should be able to open and close the simulator' do
    cmd = "ps auxw | grep \"iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" | grep -v grep"

    quit_simulator
    sleep(2)
    expect(`#{cmd}`.split("\n").count).to be == 0

    launch_simulator
    sleep(4)
    expect(`#{cmd}`.split("\n").count).to be == 1
  end

  describe 'deprecations:' do
    it '.enable_accessibility_on_simulators' do
      out = capture_stderr do
        Calabash::Cucumber::SimulatorAccessibility.enable_accessibility_on_simulators
      end
      expect(out).to_not be == nil
    end
  end
end

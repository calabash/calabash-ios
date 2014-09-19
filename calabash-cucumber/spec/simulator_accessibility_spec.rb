require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/launcher'
require 'sim_launcher'

include Calabash::Cucumber::SimulatorAccessibility

unless Resources.shared.travis_ci?
  describe 'simulator accessibility tool' do

    it 'should be able to find the simulator app support directory' do
      path = simulator_app_support_dir
      expect(File.exist?(path)).to be == true
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
end

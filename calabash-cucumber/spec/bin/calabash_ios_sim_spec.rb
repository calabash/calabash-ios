require File.expand_path(File.join(__FILE__, '..', '..', 'spec_helper'))
require File.expand_path(File.join(__FILE__, '..', '..', '..', 'bin', 'calabash-ios-sim'))
require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/wait_helpers'
require 'run_loop'

unless Resources.shared.travis_ci?
  describe 'calabash ios sim cli' do

    let(:sim_control) { RunLoop::SimControl.new }

    it '#quit_sim' do
      sim_control.launch_sim
      quit_sim
      expect(sim_control.sim_is_running?).to be == false
    end

    it '#calabash_sim_reset' do
      # @todo figure out how and if this can/should be tested
      calabash_sim_reset
    end

    it '#calabash_sim_accessibility' do
      # @todo figure out how and if this can/should be tested
      calabash_sim_accessibility
    end
  end
end

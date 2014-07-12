require File.expand_path(File.join(__FILE__, '..', '..', 'spec_helper'))
require File.expand_path(File.join(__FILE__, '..', '..', '..', 'bin', 'calabash-ios-sim'))
require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/wait_helpers'

describe 'calabash ios sim cli' do

  it 'should deprecate the sim_quit method' do
    out = capture_stderr do
      quit_sim
    end
    tokens = out.string.split("\n")
    puts tokens
    expect(tokens[1]).to be == "WARN: deprecated '0.9.169' - 'use Calabash::Cucumber::SimulatorAccessibility.quit_simulator'"
  end

  it 'should be able to reset the content and settings of the simulator' do
    calabash_sim_reset
    expect(existing_simulator_support_sdk_dirs.count).to be == 1
  end

end
require 'rubygems'
require 'irb/completion'
require 'irb/ext/save-history'
require 'awesome_print'
AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

# 25 entries in the list
IRB.conf[:SAVE_HISTORY] = 50

# Store results in home directory with specified file name
IRB.conf[:HISTORY_FILE] = '.irb-history'

require 'calabash-cucumber/operations'

# legacy support - module was deprecated 0.9.169
# and replaced with simulator_launcher
require 'calabash-cucumber/launch/simulator_helper'

require 'calabash-cucumber/launch/simulator_launcher'
SIM=Calabash::Cucumber::SimulatorLauncher.new()

extend Calabash::Cucumber::Operations

def embed(x,y=nil,z=nil)
  puts "Screenshot at #{x}"
end

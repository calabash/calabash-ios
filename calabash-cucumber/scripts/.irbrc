require 'rubygems'
require 'irb/completion'
require 'irb/ext/save-history'

begin
  require 'awesome_print'
rescue LoadError => e
  msg = ["Caught a LoadError: could not load 'awesome_print'",
         "#{e}",
         '',
         'Use bundler (recommended) or uninstall awesome_print.',
         '',
         '# Use bundler (recommended)',
         '$ bundle update',
         '$ bundle exec calabash-ios console',
         '',
         '# Uninstall',
         '$ gem update --system',
         '$ gem uninstall -Vax --force --no-abort-on-dependent awesome_print']
  puts msg
  exit(1)
end

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

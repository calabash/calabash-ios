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

IRB.conf[:SAVE_HISTORY] = 50
IRB.conf[:HISTORY_FILE] = '.irb-history'

require 'calabash-cucumber/operations'
extend Calabash::Cucumber::Operations

require 'calabash-cucumber/console_helpers'
include Calabash::Cucumber::ConsoleHelpers

def embed(x,y=nil,z=nil)
  puts "Screenshot at #{x}"
end

require "calabash-cucumber"

def preferences
  Calabash::Cucumber::Preferences.new
end

def disable_usage_tracking
  preferences.usage_tracking = "none"
  puts "Calabash will not collect usage information."
  "none"
end

def enable_usage_tracking(level="system_info")
  preferences.usage_tracking = level
  puts "Calabash will collect statistics using the '#{level}' rule."
  level
end


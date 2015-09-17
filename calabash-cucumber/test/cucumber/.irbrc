require 'irb/completion'
require 'irb/ext/save-history'
require 'benchmark'
require 'run_loop'
require 'awesome_print'
require 'calabash-cucumber/operations'

AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = '.irb-history'

def World(*world_modules, &proc)
  world_modules.each { |mod|
    include mod
    puts "loaded '#{mod}'"
  }
end

begin
  require 'pry'
  Pry.config.history.should_save = false
  Pry.config.history.should_load = false
  require 'pry-nav'
rescue LoadError => _

end

extend Calabash::Cucumber::Operations
include Calabash::Cucumber::IPad

def embed(x,y=nil,z=nil)
  puts "Screenshot at #{x}"
end

if ENV['APP']
  app = ENV['APP']
else
  app = File.expand_path('./LPSimpleExample-cal.app')
  ENV['APP'] = app
end

unless File.exist?(app)
  raise "Expected app '#{app}' to exist.\nYou can build the app with `make app-cal`"
end

puts "APP => '#{app}'"

motd=["Let's get this done!", 'Ready to rumble.', 'Enjoy.', 'Remember to breathe.',
      'Take a deep breath.', "Isn't it time for a break?", 'Can I get you a coffee?',
      'What is a calabash anyway?', 'Smile! You are on camera!', 'Let op! Wild Rooster!',
      "Don't touch that button!", "I'm gonna take this to 11.", 'Console. Engaged.',
      'Your wish is my command.', 'This console session was created just for you.']
puts "#{motd.sample()}"


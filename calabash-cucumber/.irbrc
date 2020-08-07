require 'irb/completion'
require 'irb/ext/save-history'
require 'benchmark'
require 'calabash-cucumber'
require "run_loop"
require 'command_runner'

AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = '.irb-history'

IRB.conf[:AUTO_INDENT] = true

IRB.conf[:PROMPT][:CALABASH_IOS] = {
  :PROMPT_I => "calabash-ios #{Calabash::Cucumber::VERSION}> ",
  :PROMPT_N => "calabash-ios #{Calabash::Cucumber::VERSION}> ",
  :PROMPT_S => nil,
  :PROMPT_C => "> ",
  :AUTO_INDENT => false,
  :RETURN => "%s\n"
}

IRB.conf[:PROMPT_MODE] = :CALABASH_IOS

begin
  require 'pry'
  Pry.config.history_save = false
  Pry.config.history_load = false
  require 'pry-nav'
rescue LoadError => _

end

spec_resources = './spec/resources.rb'
print "require '#{spec_resources}'..."
require spec_resources
puts 'done!'

puts ''
puts '#       =>  Useful Methods  <=          #'
puts '> xcode       => Xcode instance'
puts '> instruments => Instruments instance'
puts '> simcontrol  => SimControl instance'
puts '> default_sim => Default simulator'
puts '> verbose     => turn on DEBUG logging'
puts '> quiet       => turn off DEBUG logging'
puts ''

def xcode
  @xcode ||= RunLoop::Xcode.new
end

def instruments
  @instruments ||= RunLoop::Instruments.new
end

def simcontrol
  @simcontrol ||= RunLoop::SimControl.new
end

def default_sim
  @default_sim ||= lambda do
    name = RunLoop::Core.default_simulator(xcode)
    simcontrol.simulators.find do |sim|
      sim.instruments_identifier(xcode) == name
    end
  end.call
end

def verbose
  ENV['DEBUG'] = '1'
end

def quiet
  ENV['DEBUG'] = '1'
end

motd=["Let's get this done!", 'Ready to rumble.', 'Enjoy.', 'Remember to breathe.',
      'Take a deep breath.', "Isn't it time for a break?", 'Can I get you a coffee?',
      'What is a calabash anyway?', 'Smile! You are on camera!', 'Let op! Wild Rooster!',
      "Don't touch that button!", "I'm gonna take this to 11.", 'Console. Engaged.',
      'Your wish is my command.', 'This console session was created just for you.']
puts "Calabash iOS says, \"#{motd.sample()}\""


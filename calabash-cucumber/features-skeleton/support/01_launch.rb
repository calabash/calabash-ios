require 'calabash-cucumber/launcher'

module Calabash::Launcher
  @@launcher = nil

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  def self.launcher=(launcher)
    @@launcher = launcher
  end
end

Before do |scenario|
  launcher = Calabash::Launcher.launcher
  options = {
    # Add launch option here.
  }

  launcher.relaunch(options)
  launcher.calabash_notify(self)
end

After do |scenario|

end


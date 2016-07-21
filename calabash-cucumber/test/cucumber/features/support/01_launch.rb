require 'calabash-cucumber/launcher'

module Calabash::Launcher
  @@launcher = nil

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  def self.launcher=(launcher)
    @@launcher = launcher
  end

  def self.options
    env = ENV["CBX_LAUNCHER"]
    if env
      cbx_launcher = env.to_sym
      {
        :gesture_performer => :device_agent,
        :cbx_launcher => cbx_launcher
      }
    else
      {
        :gesture_performer => :instruments
      }
    end
  end
end

Before do |scenario|
  launcher = Calabash::Launcher.launcher
  options = {
    # Add launch options here.
  }

  merged_options = options.merge(Calabash::Launcher.options)
  launcher.relaunch(merged_options)
end

After do |scenario|

end

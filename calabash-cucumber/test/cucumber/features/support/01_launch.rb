require 'calabash-cucumber/launcher'
require 'singleton'

module Calabash
  class LaunchControl
    include Singleton
    attr_reader :launcher

    def launcher
      @launcher ||= Calabash::Cucumber::Launcher.new
    end
  end
end

Before('@reset_app_before_hook') do
  ENV['RESET_BETWEEN_SCENARIOS'] = '1'
end

Before('@reset_simulator_before_hook') do
  launcher = Calabash::LaunchControl.instance.launcher
  if launcher.simulator_target?
    launcher.reset_simulator
  elsif xamarin_test_cloud?
    ENV['RESET_BETWEEN_SCENARIOS'] = '1'
  else
    # no-op for devices
  end
end

Before do |_|
  launcher = Calabash::LaunchControl.instance.launcher
  launch_options =
        {

        }

  launcher.relaunch(launch_options)
  launcher.calabash_notify(self)

  ENV['RESET_BETWEEN_SCENARIOS'] = '0'
end

After do |_|
  launcher = Calabash::LaunchControl.instance.launcher
  unless launcher.calabash_no_stop?
    calabash_exit
    if launcher.active?
      launcher.stop
    end
  end
end

at_exit do
  launcher = Calabash::LaunchControl.instance.launcher
  if launcher.simulator_target?
    if launcher.calabash_no_stop?

    else
      launcher.simulator_launcher.stop
    end
  end
end

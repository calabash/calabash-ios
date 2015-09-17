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
    keychain_clear
  elsif xamarin_test_cloud?
    ENV['RESET_BETWEEN_SCENARIOS'] = '1'
    keychain_clear
  else
    keychain_clear
    # no-op for devices
  end
end

Before do |_|
  launcher = Calabash::LaunchControl.instance.launcher
  launch_options =
        {
              :launch_retries => ENV['TRAVIS'] ? 7 : 2
        }

  launcher.relaunch(launch_options)
  launcher.calabash_notify(self)
end

After do |_|
  ENV['RESET_BETWEEN_SCENARIOS'] = '0'
end


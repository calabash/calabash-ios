########################################
#                                      #
#       Important Note                 #
#                                      #
#   When running calabash-ios tests at #
#   www.xamarin.com/test-cloud         #
#   this file will be overwritten by   #
#   a file which automates             #
#   app launch on devices.             #
#                                      #
#   Don't rely on this file being      #
#   present when running at            #
#   Xamarin Test Cloud                 #
#                                      #
########################################

require 'calabash-cucumber/launcher'

# noinspection ALL
module LaunchControl
  @@launcher = nil

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  def self.launcher=(launcher)
    @@launcher = launcher
  end
end

Before do |scenario|
  launcher = LaunchControl.launcher
  unless launcher.calabash_no_launch?
    launcher.relaunch
    launcher.calabash_notify(self)
  end
end

After do |scenario|
  launcher = LaunchControl.launcher
  unless launcher.calabash_no_stop?
    calabash_exit
    if launcher.active?
      launcher.stop
    end
  end
end

at_exit do
  launcher = LaunchControl.launcher
  if launcher.simulator_target?
    Calabash::Cucumber::SimulatorHelper.stop unless launcher.calabash_no_stop?
  end
end

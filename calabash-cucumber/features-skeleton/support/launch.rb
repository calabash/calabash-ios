########################################
#                                      #
#       Important Note                 #
#                                      #
#   When running calabash-ios tests at #
#   www.lesspainful.com                #
#   this file will be overwritten by   #
#   a file which automates             #
#   app launch on devices.             #
#                                      #
#   Don't rely on this file being      #
#   present when running at            #
#   www.lesspainful.com.               #
#                                      #
#  Only put stuff here to automate     #
#  iOS Simulator.                      #
#                                      #
#  You can put your app bundle path    #
#  for automating simulator app start: #
#  Uncomment APP_BUNDLE_PATH =..       #
#                                      #
########################################

require 'calabash-cucumber/launch/simulator_helper'

# Uncomment and replace ?? appropriately
# This should point to your Simulator build
# which includes calabash framework
# this is usually the Calabash build configuration
# of your production target.
#APP_BUNDLE_PATH = "~/Library/Developer/Xcode/DerivedData/??/Build/Products/Calabash-iphonesimulator/??.app""
#

def relaunch
  if ENV['NO_LAUNCH'].nil?
    Calabash::Cucumber::SimulatorHelper.relaunch(app_path,ENV['SDK_VERSION'],ENV['DEVICE'] || 'iphone')
  end
end


def app_path
  ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
end

##TODO Reset simulator between features!

Before do |scenario|
  relaunch
end

at_exit do
  if ENV['NO_LAUNCH'].nil?
    Calabash::Cucumber::SimulatorHelper.stop
  end
end
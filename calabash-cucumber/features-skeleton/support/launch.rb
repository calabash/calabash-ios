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
require 'sim_launcher'

# Uncomment and replace ?? appropriately
# This should point to your Simulator build
# which includes calabash framework
# this is usually the Calabash build configuration
# of your production target.
#APP_BUNDLE_PATH = "~/Library/Developer/Xcode/DerivedData/??/Build/Products/Calabash-iphonesimulator/??.app""
#

def reset_app_jail(sdk, app_path)
  app = File.basename(app_path)
  bundle = `find "#{ENV['HOME']}/Library/Application Support/iPhone Simulator/#{sdk}/Applications/" -type d -depth 2 -name #{app} | head -n 1`
  return if bundle.empty? # Assuming we're already clean

  sandbox = File.dirname(bundle)
  ['Library', 'Documents', 'tmp'].each do |dir|
    FileUtils.rm_rf(File.join(sandbox, dir))
  end
end

def relaunch
  if ENV['NO_LAUNCH'].nil?
    sdk = ENV['SDK_VERSION'] || SimLauncher::SdkDetector.new().latest_sdk_version
    path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
    reset_app_jail(sdk, path)

    Calabash::Cucumber::SimulatorHelper.relaunch(path,ENV['SDK_VERSION'],ENV['DEVICE'] || 'iphone')
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
  if ENV['NO_LAUNCH'].nil? and ENV['NO_STOP'].nil?
    Calabash::Cucumber::SimulatorHelper.stop
  end
end

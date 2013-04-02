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

require 'calabash-cucumber/calabash_launcher'

# Uncomment and replace ?? appropriately
# This should point to your Simulator build
# which includes calabash framework
# this is usually the Calabash build configuration
# of your production target.
#APP_BUNDLE_PATH = "~/Library/Developer/Xcode/DerivedData/??/Build/Products/Calabash-iphonesimulator/??.app"
#


Before do |scenario|
  @launcher = Calabash::Cucumber::Launcher.new
  @launcher.relaunch
  @launcher.calabash_notify(self)
end

After do |scenario|
  unless @launcher.calabash_no_stop?
    if @launcher.active?
      @launcher.stop
    else
      Calabash::Cucumber::SimulatorHelper.stop
    end
  end
end
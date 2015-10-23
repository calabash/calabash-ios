require 'calabash-cucumber/launcher'

# http://calabashapi.xamarin.com/ios/file.ENVIRONMENT_VARIABLES.html#label-APP+and+APP_BUNDLE_PATH
#
# In order for Calabash to launch an app on simulator, it must have the path 
# to the .app.  By default, Xcode builds to a DerivedData directory:
#
# ~/Library/Developer/Xcode/DerivedData/??/Build/Products/Debug-iphonesimulator/??.app
#
# Calabash tries to analyze the DerivedData directory to find your .app, but
# there are often several possible matches.  This makes automatically detecting
# the right .app difficult to impossible.
#
# If Calabash cannot find your .app or if you want to be sure that Calabash is
# targeting the correct .app, you can set the APP variable before launching:
#
# $ APP=/path/to/Your.app bundle exec cucumber
#
# You can also do this in a config/cucumber.yml profile.
#
# app:       APP=/path/to/Your.app
# default:  -p app
#
# $ bundle exec cucumber
#
# The Calabash iOS Smoke Test app has several very useful scripts for building
# and staging .apps and .ipas to a local directory.
#
# * https://github.com/calabash/ios-smoke-test-app/blob/master/CalSmokeApp/bin/make/app-cal.sh
# * https://github.com/calabash/ios-smoke-test-app/blob/master/CalSmokeApp/bin/xcode-build-phase/stage-CalSmoke-cal-products.sh
#
# The second script is an Xcode Run Script. It copies ipas and apps to a local
# directory after an Xcode build:
#
# Products/app/Your.app
# Products/ipa/Your.ipa
#
# APP_BUNDLE_PATH = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData/??/Build/Products/Calabash-iphonesimulator/??.app"
# You may uncomment the above to overwrite the APP_BUNDLE_PATH
# However the recommended approach is to let Calabash find the app itself
# or set the environment variable APP_BUNDLE_PATH


Before do |scenario|
  @calabash_launcher = Calabash::Cucumber::Launcher.new
  unless @calabash_launcher.calabash_no_launch?
    @calabash_launcher.relaunch
    @calabash_launcher.calabash_notify(self)
  end
end

After do |scenario|
  unless @calabash_launcher.calabash_no_stop?
    calabash_exit
    if @calabash_launcher.active?
      @calabash_launcher.stop
    end
  end
end

at_exit do
  launcher = Calabash::Cucumber::Launcher.new
  if launcher.simulator_target?
    launcher.simulator_launcher.stop unless launcher.calabash_no_stop?
  end
end

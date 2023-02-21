### 0.23.6

* Fix the casting of `WAIT_TIMEOUT` environment

### 0.23.5

* Start to use `WAIT_TIMEOUT` environment to decide how long to wait for `Calabash::Cucumber::WaitHelpers.wait_for_condition` (used from `wait_for_none_animating` / `wait_for_no_network_indicator` / `wait_for_transition`)

### 0.23.1

* Added server version 0.23.0

### 0.23.0

* Support for Cucumber 6

### 0.22.2
Fix irb/pry settings #1426

#### Calabash Server
Fix waiting for none animation for Xcode 12 https://github.com/calabash/calabash-ios-server/pull/461

### 0.22.1
reverted

### 0.22.0
reverted

### 0.21.10

Remove bundler as a dependency.

The embedded LPServer was build with Xcode 10.2 on macOS Mojave.

The server version is 0.21.8 (not a typo), it is just trailing behind
the gem version.

### 0.21.9

Never released.

### 0.21.8

* gem: calabash-ios binary does not need CFPropertyList #1400

### 0.21.7

This release allows Calabash iOS to used with json 2.0
and cucumber 3.0.  This will also allow users to update
their ruby to 2.5.x.

Test Cloud users will need to pin their ruby version to
2.3.x and the json and cucumber versions.  To your Gemfile
add the following:

```
gem "json", "1.8.6"
gem "cucumber", "2.99.0"
```

Test submitted to Test Cloud with json > 1.8.6 and cucumber 3.x
will fail validation.

* Allow to use newest run_loop versions #1398
* Do not bind Calabash to any versions of Cucumber #1396

Thanks @JoeSSS.

### 0.21.6

* Removed Frank related code and tests #1378
* Updated project for blue ocean CI #1379

### 0.21.5

This release requires a Calabash iOS Server update.

Adds support for touch-and-hold (first press duration) for iOS 11
drag and drop.

### 0.21.4

This releae requires a Calabash iOS Server update.

* Gem: pin cucumber to 2.x #1359

### 0.21.2

This release requires a Calabash iOS Server update.

* Updated XCUIElementType documentation #1335
* Use correct query for navigation bar with title on iOS 11 #1333
  @MortenGregersen

### 0.21.1

* Coordinates: full-screen pans start and end closer to screen edge #1329
* Support the new view hierarchy of the navigation bar on iOS 11 #1325 @MortenGregersen
* Remove usage tracking to comply with EU GDPR 2018 #1320

### 0.20.5

This release adds a public API for manually managing SpringBoard alerts.
This behavior is only available when running with Xcode 8.x. See this
pull-request for API examples: [run\_loop#611](https://github.com/calabash/run_loop/pull/611).

This release does not require a server update.

* IRB: rescue LoadError on require 'irb/\*' #1294
* DeviceAgent: add public API for managing SpringBoard alerts #1292
* Fix logical inconsistency in warning emitted by
  Launcher#calabash\_no\_launch? #1275 @duboviy
* Fix typo in contributing doc #1264 @acroos
* Update Calabash.podspec #1253 @nadzeya

### 0.20.4

This release, combined with DeviceAgent 1.0.4 and run-loop 2.2.4
fixes several critical bugs related to:

1. Code signing the DeviceAgent-Runner.app for physical devices
2. Text entry and keyboard interactions
3. Dismissing SpringBoard alerts

Definining a `CODE_SIGN_IDENTITY` is no longer necessary, but is
supported if for some reason you require a specific identity for
signing.

We have identified a flaw in text entry on i386 simulators and armv7
devices.  At the moment, we have no fail-proof solution.  We recommend
that you do not test on i386 simulators or armv7 devices.

* HTTP: dismiss SpringBoard alerts before and after most LPServer calls #1245
* DeviceAgent:API: #to\_s and #inspect #1215
* Implement Automator::DeviceAgent#clear\_text #1205
* Calabash can return the type of the visible keyboard #1207

### 0.20.3

This release, combined with DeviceAgent 1.0.2, and run-loop 2.2.2,
fixes several critical bugs related to:

1. Code signing the DeviceAgent-Runner.app for physical devices
2. Text entry and keyboard interactions

0.20.0 shipped with a mistake in the `Calabash::Cucumber::DeviceAgent`
API.  That module incorrect forwarded missing methods to `Core`.  Some
users will experience failing tests if they are making calls to `Core`
methods through the `Core::device_agent` method.  You should only be
calling `Core#device_agent` if absolutely necessary.  As time goes on,
we are finding edge cases were the DeviceAgent query engine is extremely
slow to respond.

* Automator::DeviceAgent: search for any first responder for return key
  type #1204
* Automator::DeviceAgent#tap\_keyboard\_action\_key should operate on
  button only #1202 @ark-konopacki
* Keyboard: Keyboard: text from first responders should check other views
  #1199
* DeviceAgent: automator skips keyboard visible checks #1197
* Console attach for DeviceAgent + automatic console\_attach #1192
* Full screen gestures should use screen dimensions #1190
* Update the Core#scroll methods #1189
* Capture run\_loop and xcode versions in tracker #1188 @ark-konopacki
* Replace user\_id with distinct\_id #1187 @ark-konopacki
* Adds device agent implementation for pinch #1186 @jescriba
* Added polish "message of day" #1184 @ark-konopacki
* 2x-bridge: pass string to fail method (as Calabash 0.x does) #1174
  @JoeSSS
* Refactor DeviceAgent public API screenshot and fail #1170
* Gem: force httpclient 2.7.1 or higher #1165
* Core: add #ios10?

### 0.20.0

This release provides support for iOS 9 and iOS 10 with Xcode 8.

If you need to test iOS 8, you must have Xcode 7 installed. macOS Sierra
does not support Xcode 7, so keep that in mind when making your macOS
upgrade plans.

### DeviceAgent

Apple has removed UIAutomation from Xcode 8. Our replacement for UIAutomation
is DeviceAgent. DeviceAgent is based on Apple's XCUITest framework.

Our goal for this transition is 100% backward compatibility with
UIAutomation.  We think we are close, but we need your help to discover
what is missing.  Since UIAutomation is not available, all `uia_*` calls
now raise an error when tests are run with DeviceAgent.  The text of the
error will have workarounds and examples to help you transition your
tests.  When you find something you cannot do with DeviceAgent, please
create a GitHub issue.

Please see the
[DeviceAgent](https://github.com/calabash/calabash-ios/wiki/DeviceAgent)
on the Calabash iOS Wiki for more details.

### CODE\_SIGN\_IDENTITY

Testing on physical devices now has an additional requirement:
code signing.

```
# Find the valid code signing identities
$ xcrun security find-identity -v -p codesigning
  1) 18<snip>84 "iPhone Developer: Your Name (ABCDEF1234)"
  2) 23<snip>33 "iPhone Distribution: Your Company Name (A1B2C3D4EF)"
  3) 38<snip>11 "iPhone Developer: Your Colleague (1234ABCDEF)"

# Chose an "iPhone Developer" certificate.

$ CODE_SIGN_IDENTITY="iPhone Developer: Your Name (ABCDEF1234)" \
   DEVICE_TARGET=< udid | name> \
   DEVICE_ENDPOINT=http://< ip >:37265 \
   bundle exec cucumber
```

Many thanks to: @ark-konopacki, @TeresaPeters, @JoeSSS,
@MortenGregersen, @haocuihc, and every else on
[Gitter](https://gitter.im/calabash/calabash0x?utm_source=share-link&utm_medium=link&utm_campaign=share-link)
who has helped test.

And a big thank you to @nicholasbarron for his clutch PR.

* Map: dismiss SpringBoard alerts when DeviceAgent is available #1151
* Public query and gesture API for DeviceAgent. #1150
* UIA methods will raise an error with examples if called when running
  with DeviceAgent #1148
* Replaced calls to touch() to use Hash argument instead of String #1144
  @nicholasbarron
* calabash\_exit does not raise an error if the server is not running #1139
* Added missing word 'on' in message #1122 @ark-konopacki

### 0.19.2

This is a server only release.  The gem behavior has not changed.

The 0.19.2 server fixes touch coordinates for legacy applications on
iPhone 6 Plus form factors.  Legacy applications do not have the correct
icons, launch images, and image assets (@3x) to support non-scaled
display on iPhone 6 and iPhone 6 Plus form factors.

### 0.19.1

* UIA: automatically attach in the IRB #1102
* Remove Playback API references from keyboard\_helpers #1101
* Podspec path to server should be "Calabash" not "calabash" #1098
  @ark-konopacki @tachtevrenidis
* Launcher: fix grammar in log message generated by console\_attach #1093
  @TersaP
* Add nodeType to tree #1088 @TeresaP
* Fix undefined method "embed" in Calabash::Cucumber.map #1086
* Gem: pin listen to 3.0.6 #1084
* IRB: save pry history to local file #1082
* Update ENVIRONMENT\_VARIABLES.md docs for APP\_BUNDLE\_PATH #1081
  @sapieneptus

### 0.19.0

This release removes almost all deprecated methods.  Further, Calabash
will no longer respond to legacy environment variables.  See the
changelog/0.19.0.md for specific details.

* Launcher: restore public API for device/simulator_target? #1078
  @JoeSSS, @TeresaP
* Improve console experience #1073
* Remove 'sim location' CLI tool #1071
* Added tree feature for console #1070 @ark-konopacki
* Added briar's marks extension for irbc #1068 @ark-konopacki
* Complete switch to run loop 2.1.0 interface #1069
* Change Map module to class and provide class methods #1065 @svandeven
* Use tap_keyboard_action_key instead of done #1057 @lucatorella
* Launcher#check_server_gem_compatibility should be a post-launch check
  #1051
* Launcher: use RunLoop 2.1.0 APIs where possible #1050
* Core: remove references to @calabash_launcher Cucumber World variable
  #1049
* Deprecate Launcher#calabash_notify #1048
* Deprecate old Launcher behaviors and use new RunLoop APIs in #relaunch
  #1047
* Launcher: deprecated #default_uia_strategy #1046
* Move http methods out of launcher #1044
* Rotation: remove playback API - since 0.16.2 #1040
* Replace NO_STOP with QUIT_APP_AFTER_SCENARIO #1038
* Unify logging between RunLoop and Calabash #1035
* Gem: remove deprecated.rb #1034
* Remove more deprecated Device behaviors #1033
* Remove CALABASH_VERSION_PATH #1028
* Remove unnecessary methods from Launcher #1027
* Remove deprecated methods for 0.19.0 #1026
* Remove the Playback API #1025
* Remove deprecated XcodeTools, PlistBuddy, and SimulatorAccessibility
  #1024
* Remove deprecated methods from KeyboardHelpers #1023
* Remove deprecated ENV variables and constants #1022
* Core: undeprecate #set_text #1021
* CLI: remove 'update' command #1020
* Remove sim_launcher gem dependency and SimulatorLauncher class #1016
* Remove KeyboardHelpers.done #1004
* Screen coordinates are incorrect when running in Zoomed mode #998
* Remove the sim_launcher dependency #921
* Cannot query UIWebView by accessibilityIdentifier or
  accessibilityLabel #735

### 0.18.2

* Replace automatic .app detection with RunLoop implementation #1011
* Gem: pin rake to ~> 10.5; rspec 3.4 is not compatible #1010
* Launcher: remove TCC privacy settings #1009
* Keyboard: log that #done is going to be removed #1007
* Launcher: fix error reporting in #new\_run\_loop #1006

### 0.18.1

* CLI: use RunLoop::Ipa or RunLoop::App for version check #996
* Update skeleton support/dry\_run to load predefined steps #995
* Fix formatter import problem #994
* SimLauncher: fix autodetection of app bundle #974 @ark-konopacki

### 0.18.0

This release contains a new version of the server that provides
iframe support for css selectors.

* Fix `sim locale` command line tool #987
* Added Calabash.podspec #979 @ark-konopacki

### 0.17.1

This release contains a new version of the server that fixes
scrolling in WebViews.

* Launcher#reset\_simulator should call RunLoop::CoreSimulator.erase #975
  @ark-konopacki
* Remove the lib/calabash directory and put Dylibs module in
  Calabash::Cucumber #967
* Use run loop cache for all strategies when attaching #960
* Track GitLab CI #958
* Don't immediately return true for simulator? if simulator\_details is
  empty #957 @MikeNicholls
* Tracker: catch errors and log them to a file #954
* Tracker: add missing requires to avoid throwing errors #952
* Use UIAutomation JavaScript to touch keyboard Delete key #942 @MikeNicholls

### 0.17.0

This release contains several changes that are not backward compatible.

* requires ruby >= 2.0
* the backdoor API has become more flexible, but some users will find
  existing backdoors no longer work or behave in unexpected ways
* RESET_APP_BETWEEN_SCENARIOS no longer resets the simulator, it only
  resets the app sandbox.  The reset_app_sandbox method has been
  deprecated; it is now a no op. See #878 for details.

This release adds user tracking.

* Launcher: post usage data at relaunch #937
* Store user preferences in ~/.calabash/preferences/preferences.json
  #933
* Fix the "reset app sandbox between Scenarios" behavior #923
* RESET_APP_BETWEEN_SCENARIOS is still resetting the simulator not just
  the app sandbox #878
* Gem: min run-loop version is 2.0 #919
* Calabash can manage a ~/.calabash directory #909
* Docs: minor versions can contain breaking changes #905
* Gem: allow any version of cucumber #904
* Add client for shake route #902 @tommeier
* send_app_to_background uses "suspend" server route #901
* Update backdoor method to handle new LPBackdoorRoute behavior #894
* README rewrite for 0.17 #892
* Drop ruby 1.9 support; >= 2.0 is required #883
* Update the features skeleton #882
* Fixing wiki link for updating calabash version #869 @yakovsh

### 0.16.4

This is a patch release for the server.  Xcode 7.0.1 introduced
new rules for embedding bitcode in libraries.  The Objective-C
libraries included in this release are compatible with these
new rules.

* Improve server build rake task to complement the new server build system #864

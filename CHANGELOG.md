### 0.17.1

This release contains a new version of the simulator that fixes
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


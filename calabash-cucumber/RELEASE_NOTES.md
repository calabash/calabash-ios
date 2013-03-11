# Release Notes

## 0.9.134
[Link to 0.9.x branch](https://github.com/calabash/calabash-ios/tree/ebda65ca86ebca2fdba4cd71e8ff5e0cd93f7e3c).

[Announcement](https://groups.google.com/d/msg/calabash-ios/38kpMqUSMsM/D__RjbcdrPwJ).

This minor release fixes bugs and adds a few features.

Two server pull requests where merged:

- https://github.com/calabash/calabash-ios-server/pull/13
Add ability to query the log file and app delegate properties

- https://github.com/calabash/calabash-ios-server/pull/14
Fix problem with windows that don't have an identity transform.
Fixes issue with pressing UIAlertButton when device is not in portrait orientation as discussed [here](https://groups.google.com/forum/?fromgroups=#!topic/calabash-ios/wjkDSVeINg8).

- Calabash iOS now comes with a simple default page object implementation:

[https://github.com/calabash/calabash-ios/blob/0.9.x/calabash-cucumber/lib/calabash-cucumber/ibase.rb](https://github.com/calabash/calabash-ios/blob/0.9.x/calabash-cucumber/lib/calabash-cucumber/ibase.rb)

This takes care of the plumbing needed when using the page object pattern with Cucumber and Calabash iOS.

The cross-platform-example:

[https://github.com/calabash/x-platform-example](https://github.com/calabash/x-platform-example)

has been updated to use this new class, and samples can be seen [here](https://github.com/calabash/x-platform-example/blob/master/features/ios/pages/welcome_page_ios.rb).

and in a more complex setting [here](https://github.com/calabash/x-platform-example/blob/master/features/ios/pages/main_page_ios.rb)

Questions, comments, feedback are welcome here.

Please report any found bugs (including descriptions of how to reproduce) via

https://github.com/calabash/calabash-ios/issues

| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://travis-ci.org/calabash/calabash-ios.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios)| [![Build Status](https://travis-ci.org/calabash/calabash-ios.svg?branch=develop)](https://travis-ci.org/calabash/calabash-ios-server)| [![GitHub version](https://badge.fury.io/gh/calabash%2Fcalabash-ios.svg)](http://badge.fury.io/gh/calabash%2Fcalabash-ios) |[![License](https://img.shields.io/badge/license-Eclipse-blue.svg)](http://opensource.org/licenses/EPL-1.0) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|

## Calabash iOS

>After delivering support for the final releases of iOS 11 and Android 8 operating systems, Microsoft will discontinue our contributions to developing Calabash, the open-source mobile app testing tool. We hope that the community will continue to fully adopt and maintain it. As part of our transition on the development of Calabash, we've provided an overview of mobile app UI and end-to-end testing frameworks as a starting point for teams who are looking to re-evaluate their testing strategy. Please see our [Mobile App Testing Frameworks Overview](https://docs.microsoft.com/en-us/appcenter/migration/test-cloud/frameworks) document.

[http://calaba.sh/](http://calaba.sh/)

Calabash is an automated testing technology for Android and iOS native and hybrid applications.

Calabash is a free-to-use open source project that is developed and maintained by [Xamarin](http://xamarin.com).

While Calabash is completely free, Xamarin provides a number of commercial services centered around Calabash and quality assurance for mobile, namely Xamarin Test Cloud consisting of hosted test-execution environments which let you execute Calabash tests on a large number of Android and iOS devices.  For more information about the Xamarin Test Cloud visit [http://xamarin.com/test-cloud](http://xamarin.com/test-cloud).

## Requirements

Xamarin Studio users should visit [http://developer.xamarin.com/testcloud/](http://developer.xamarin.com/testcloud/) for setup instructions and requirements.

* macOS High Sierra and Mojave
* Xcode 9.4.1 or Xcode 10.0
* ruby at least ruby 2.3.x

For the best Ruby experience we recommend that you use a managed Ruby
like [rbenv](https://github.com/sstephenson/rbenv) or [rvm](https://rvm.io/)).

Please do *not* install gems with `sudo`

For more information about ruby on MacOS, see these Wiki pages:

* [Ruby on MacOS](https://github.com/calabash/calabash-ios/wiki/Ruby-on-MacOS)
* [Best Practice: Never install gems with sudo](https://github.com/calabash/calabash-ios/wiki/Best-Practice%3A--Never-install-gems-with-sudo)

## IMPORTANT

Calabash uses private APIs to inspect your app's view hierarchy.  Apps that include the Calabash iOS
Server will be rejected if they are submitted to the AppStore.  The tutorials below describe a number
ways to add Calabash to your Xcode project that will ensure you do not accidently submit a binary that
will be reject because it includes Calabash.

## Getting Started

If you want to see Calabash iOS in action, head over to the [Calabash iOS Smoke Test App](https://github.com/calabash/ios-smoke-test-app) and follow the instructions in the README.  We use this app to document, demonstrate, and test Calabash iOS.  You can use this app to explore Calabash and as an example for how to configure your Xcode project and Calabash workflow.

The examples below assume you are using a managed ruby or are working in the Calabash
Sandbox:

```
$ calabash-sandbox
This terminal is now ready to use with Calabash.
To exit, type 'exit'.
```

### Step 1: Link calabash.framework

To start using Calabash in your project, you need to link an Objective-C framework (calabash.framework) to your application.  These instructions are compatible with apps
that are written in Swift.

|Tutorial|Description|
|:--------:|-----------|
|[Debug Config](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-Link-Calabash-in-Debug-config) | Use linker flags in the Debug build config to load the calabash.framework |
|[Calabash Config](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-Calabash-config) | Create a new Calabash Build Configuration |
|[-cal Target](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A--Creating-a-cal-Target) | Add a new app target to Xcode.|

If you want to get started quickly, follow the [Debug Config](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-Link-Calabash-in-Debug-config) instructions.  The [Tutorial: How to add Calabash to Xcode](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-How-to-add-Calabash-to-Xcode) wiki page discusses the merits of each approach and has instructions for using CocoaPods.

### Step 2: Run Cucumber against an iOS Simulator

The [Calabash iOS Example](https://github.com/calabash/calabash-ios-example) README has simple instructions for how to link the calabash.framwork, generate a features directory, run cucumber, and and open a Calabash console.

```
# In the directory where your .xcodeproj and Gemfile are
$ bundle exec calabash-ios gen
```

Build and run in Xcode, targeting an iOS Simulator.  Calabash will try to detect the .app you just built.

```
$ bundle exec cucumber
```

If Calabash cannot find the .app you just built, it will raise an error.  If this happens, you will to tell Calabash where it can find your .app.

By default, Xcode builds to a DerivedData directory:

```
~/Library/Developer/Xcode/DerivedData/<UDID>/Build/Products/Debug-iphonesimulator/<NAME>.app
```

Try to locate the .app and set the `APP` variable:

```
$ export APP="~/Library/Developer/Xcode/DerivedData/<UDID>/Build/Products/Debug-iphonesimulator/<NAME>.app"
$ bundle exec cucumber
```

We recommend using scripts and/or changing the location where Xcode stages build products.  The sample projects use scripts to stage binaries to a `./Products`, even when building from Xcode.  You can use the Xcode > Preferences > Locations settings to do the same.

### Where to go from here?

| Topic | Description |
|-------|-------------|
| [Getting Started](https://github.com/calabash/calabash-ios/wiki/Getting-Started) | A more in-depth tutorial using the LPSimpleExample. |
| [Testing on Physical Devices](https://github.com/calabash/calabash-ios/wiki/Testing-on-Physical-Devices) | Everything you need to know about testing on physical devices. |
| [API Docs](http://calabashapi.xamarin.com/ios) | The Calabash iOS ruby API |
| [iOS Smoke Test App](https://github.com/calabash/ios-smoke-test-app) | Demonstrates advanced features, setups, and workflows|
| [iOS WebView Test App](https://github.com/calabash/ios-webview-test-app) | Demonstrates how to interact with UIWebView and WKWebView|
| [Getting Help](https://github.com/calabash/calabash-ios/wiki) | The Calabash iOS Wiki |

## Links

* [Getting Help](https://github.com/calabash/calabash-ios/wiki#getting-help)
* [Reporting Problems](https://github.com/calabash/calabash-ios/wiki#reporting-problems)
* [Public API](http://calabashapi.xamarin.com/ios/)
* [Xamarin Studio + Ruby Client](http://developer.xamarin.com/guides/testcloud/calabash/configuring/)
* [Xamarin Studio + UITest](http://developer.xamarin.com/guides/testcloud/uitest/)
* [Contributing](CONTRIBUTING.md)
* [CHANGELOGS](https://github.com/calabash/calabash-ios/tree/master/changelog)

## License

```
Copyright (c) LessPainful APS. All rights reserved.
The use and distribution terms for this software are covered by the
Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
which can be found in the file epl-v10.html at the root of this distribution.
By using this software in any fashion, you are agreeing to be bound by
the terms of this license. You must not remove this notice, or any other,
from this software.
```

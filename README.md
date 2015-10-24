| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://travis-ci.org/calabash/calabash-ios.svg?branch=master)](https://travis-ci.org/calabash/calabash-ios)| [![Build Status](https://travis-ci.org/calabash/calabash-ios.svg?branch=develop)](https://travis-ci.org/calabash/calabash-ios-server)| [![GitHub version](https://badge.fury.io/gh/calabash%2Fcalabash-ios.svg)](http://badge.fury.io/gh/calabash%2Fcalabash-ios) |[![License](https://img.shields.io/badge/licence-Eclipse-blue.svg)](http://opensource.org/licenses/EPL-1.0) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|

## Calabash iOS

[http://calaba.sh/](http://calaba.sh/)

Calabash is an automated testing technology for Android and iOS native and hybrid applications.

Calabash is a free-to-use open source project that is developed and maintained by [Xamarin](http://xamarin.com).

While Calabash is completely free, Xamarin provides a number of commercial services centered around Calabash and quality assurance for mobile, namely Xamarin Test Cloud consisting of hosted test-execution environments which let you execute Calabash tests on a large number of Android and iOS devices.  For more information about the Xamarin Test Cloud visit [http://xamarin.com/test-cloud](http://xamarin.com/test-cloud).

## Requirements

Xamarin Studio users should visit [http://developer.xamarin.com/testcloud/](http://developer.xamarin.com/testcloud/) for setup instructions and requirements.

We recommend that you use the most recent released version of Xcode, MacOS, and Ruby.

* MacOS 10.10 or 10.11
* Xcode 6 or 7
* iOS Devices >= 7.1
* iOS Simulators >= 8.0
* ruby >= 2.0 (latest is preferred)

We recommend that you use a managed ruby (_e.g._ [rbenv](https://github.com/sstephenson/rbenv), [rvm](https://rvm.io/)) or manually manage your gem environment with [this script](http://developer.xamarin.com/guides/testcloud/calabash/configuring/osx/installing-gems/).

For more information about ruby on MacOS, see these Wiki pages:

* [Ruby on MacOS](https://github.com/calabash/calabash-ios/wiki/Ruby-on-MacOS)
* [Best Practice: Never install gems with sudo](https://github.com/calabash/calabash-ios/wiki/Best-Practice%3A--Never-install-gems-with-sudo)

## Getting Started

If you want to see Calabash iOS in action, head over to the [Calabash iOS Smoke Test App](https://github.com/calabash/ios-smoke-test-app) and follow the instructions in the README.  We use this app to document, demonstrate, and test Calabash iOS.  You can use this app to explore Calabash and as an example for how to configure your Xcode project and Calabash workflow.

### Step 1: Add calabash.framework to your project

To start using Calabash in your project, you need to link an Objective-C framework (calabash.framework) to your application.

|Tutorial|Description|
|:--------:|-----------|
|[Debug Config](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-Link-Calabash-in-Debug-config) | Use linker flags in the Debug build config to load the calabash.framework |
|[Calabash Config](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-Calabash-config) | Create a new Calabash Build Configuration |
|[-cal Target](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A--Creating-a-cal-Target) | Add a new app target to Xcode.|

If you want to get started quickly, just follow the [Debug Config]() instructions.  The [Tutorial: How to add Calabash to Xcode](https://github.com/calabash/calabash-ios/wiki/Tutorial%3A-How-to-add-Calabash-to-Xcode) wiki page discusses the merits of each approach and has instructions for using CocoaPods.

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

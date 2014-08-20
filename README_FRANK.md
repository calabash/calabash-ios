**DRAFT DRAFT DRAFT**

## Calabash Plugin for Frank

As of 0.10.0, Calabash can be used a plug-in for Frank.  This is an alpha-level feature, which is our way of saying, "We haven't worked out all the kinks yet."

Feedback is welcomed and encouraged!  We need your feedback to make this plug-in better.

* https://groups.google.com/forum/?fromgroups=#!forum/calabash-ios
* https://groups.google.com/forum/?fromgroups=#!forum/frank-discuss

Please do not cross-post.  We monitor both Google groups.

### Getting Started

To install the Frank-Calabash plugin, make sure you're using Frank 1.2.3 or above and Calabash iOS version 0.10.0 or above.

#### Installing

In your Frank project run the command:

```
# copies libFrankCalabash.a to Frank/plugins/calabash/
$ frank-calabash install
$ frank build
```

#### Uninstalling

To uninstall, run:

```
$ frank-calabash uninstall
$ frank build
```

#### < Section Title >

To use Calabash with Frank, you must modify your test scripts and hooks to let Calabash launch your app using instruments. Using Frank's sim_launcher doesn't work as Calabash relies on Apple's "public" UIAutomation launched with instruments. 

Update your features/support/env.rb to include:

```
require 'frank-calabash'
require 'calabash-cucumber/operations'
```

You can then include the Frank::Calabash module which provides two important methods:

* `launch` allows launching using instruments [1]
* `calabash_client` an object that provides access to the Calabash API [2]

- [1] http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Launcher.html#relaunch-instance_method
- [2] http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html

#### Using the Calabash API

```
$ frank-calabash console
> ??? launch ???

# Access the Calabash API via the client object
> calabash = calabash_client()
> calabash.touch("* view marked:'Second'")

# this will not work
> touch("* view marked:'Second'")
```

#### On-Device Testing

Frank does not support building a Frankified app for on-device testing.  We have been able to run Frank-Calabash on devices using the steps below.   These steps may or may not work for you.

We used the LPSimpleExample as our test project.

https://github.com/calabash/calabash-ios-example

First, make sure you've run:

```
$ frank setup
$ frank-calabash install
$ frank build
```

and you have verified that frank-calabash is working against the simulator.

Then you must build and and package your application.

##### build-frank-calabash.sh

```
#!/bin/sh

FRANK_LIB="/Users/krukow/code/calabash-ios-example/Frank"
FRANK_CAL_LIB="/Users/krukow/code/calabash-ios-example/Frank/plugins/calabash"

xcrun xcodebuild \
    -xcconfig Frank/frank.xcconfig \
    -arch armv7s \
    -configuration Debug \
    -sdk iphoneos \
    ONLY_ACTIVE_ARCH=NO \
    DEPLOYMENT_LOCATION=YES \
    DSTROOT="/Users/krukow/code/calabash-ios-example/Frank/frankified_build" \
    FRANK_LIBRARY_SEARCH_PATHS="\"${FRANK_LIB}\" \"${FRANK_CAL_LIB}\"" \
    clean build

# optionally resign the application
xcrun -sdk iphoneos PackageApplication \
    -v /Users/krukow/code/calabash-ios-example/Frank/frankified_build/LPSimpleExample.app \
    -o "${PWD}/frank.ipa"
```

To launch the app on the device, use the frank console.

```
$ frank-calabash console
> launch(app:'com.lesspainful.example.LPSimpleExample', device_target:'device')
```

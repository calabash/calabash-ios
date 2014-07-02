# Welcome to Calabash for iOS

Calabash is an automated testing technology for Android and iOS native and hybrid applications.
This repository contains support for iOS, for Android, see [Calabash Landing Page](http://calaba.sh/).

Calabash is a free open source project, developed and maintained by [Xamarin](http://xamarin.com).

While Calabash is completely free, Xamarin provides a number of commercial services centered around Calabash and quality assurance for mobile, namely Xamarin Test Cloud consisting of hosted test-execution environments which let you execute Calabash tests on a large number of Android and iOS devices. 

Please see [xamarin.com/test-cloud](http://xamarin.com/test-cloud).

This document explains how to install Calabash iOS. For introductory information about the rationale behind Calabash see

[Introducing Calabash](http://blog.lesspainful.com/2012/03/07/Calabash/).

[Change log](https://github.com/calabash/calabash-ios/tree/master/changelog)

# This guide explains how to setup and use Calabash for iOS

Running Calabash requires Mac OSX.  After completing this guide you will be able to run tests locally
against the iOS Simulator. You can also interactively explore and
interact with your application using the Calabash console.

If you have any questions about Calabash iOS, please use the google group

[http://groups.google.com/group/calabash-ios](http://groups.google.com/group/calabash-ios)

For Xamarin users, we recommend the free Xamarin [Calabash component](https://components.xamarin.com/view/calabash/) which replaces the `calabash-ios setup` step below.

For setup with CocoaPods, please follow the excellent guide from Angel G. Olloqui

[http://angelolloqui.com/blog/25-Acceptance-testing-with-Calabash-and-CocoaPods](http://angelolloqui.com/blog/25-Acceptance-testing-with-Calabash-and-CocoaPods)

and see example project: [https://github.com/calabash/calabash-ios-example](https://github.com/calabash/calabash-ios-example).

The rest of this guide was writting using XCode 5, but should also work for XCode versions >= 4.3.

*NOTE about Xcode 4.3* after upgrading to Xcode 4.3, I needed to install the command line tools from the preferences pane under "Downloads" in Xcode. Then I had to do

```
    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```

## Installation

### Prerequisites

You need to have Ruby installed. This is installed by default on MacOSX.

Verify by running `ruby -v` in a terminal. It should be at least '1.9' but we do recommend using Ruby 2.0+.

### Fast track

Note: Fast track is EXPERIMENTAL, but in our experience it works for most iOS projects.  But there *are* some project setups where it does not.

If it doesn't work in your project, you should read the section "Manual setup with Xcode" below.

For automatic setup:

1. In a terminal, go to your iOS project
    - `cd path-to-my-ios-project` (i.e. directory containing .xcodeproj file)

2. Install calabash-cucumber gem (this make take some time because of dependencies)
    - `gem install calabash-cucumber`
    - Note you may need to run `sudo gem install calabash-cucumber` if you see ERROR:  While executing gem ... (Gem::FilePermissionError)).

3. Setup your project for Calabash-iOS.
    - `calabash-ios setup` Answer the questions and read the output :)

4. Generate a skeleton features folder for your tests
    - `calabash-ios gen`

5. In Xcode, build your project using the <project-name>-cal scheme
    - ![-cal scheme](documentation/images/scheme.png "-cal scheme")

6. Run the generated test!
    - `cucumber`

If all goes well, you are now ready to write your first test.
Start by editing the file `features/my_first.feature`.

Proceed by reading details about installation below, or moving on to the
[Getting started guide](https://github.com/calabash/calabash-ios/wiki/00-Calabash-iOS-documentation).


### Note on Cocoapods

We plan on supporting Cocoapods.

Until then, please se this nice article [http://angelolloqui.com/blog/25-Acceptance-testing-with-Calabash-and-CocoaPods](http://angelolloqui.com/blog/25-Acceptance-testing-with-Calabash-and-CocoaPods)
by [@angelolloqui][https://twitter.com/angelolloqui].

Manual setup with Xcode
=======================

## Background

To use Calabash for iOS in your app, you must do two things: link with
our framework: `calabash.framework`, and install a ruby gem as
described below. You also need to link with Apple's CFNetwork
framework if you are not already using this.

For functional testing with Calabash iOS, you should create a whole separate target
by duplicating your production target in Xcode (explained below).

### Ruby and calabash-cucumber gem.

*   Install the `calabash-cucumber` gem. (You may need to do `sudo gem install calabash-cucumber`)

        krukow:~$ gem install calabash-cucumber
        Successfully installed calabash-cucumber-0.9.47
        1 gem installed
        Installing ri documentation for calabash-cucumber-0.9.47...
        Installing RDoc documentation for calabash-cucumber-0.9.47...


### Setting up Xcode project

Instructions:

* Step 1/3 is to duplicate your primary/production target.
 - Select your project in XCode and select your production target for your app.
 - Right click (or two-finger tap) your target and select "Duplicate target"
 - Select "Duplicate only" (not transition to iPad)
 - Rename your new target from ".. copy" to "..-cal"
 - From the menu select Edit Scheme and select manage schemes.
 - Rename the new scheme from ".. copy" to "..-cal"
 - Optionally, set the Product name to ..-cal in Build settings for the new target.

* Step 2/3: Link with framework.
    - Download the latest version of calabash.framework with calabash-ios gem command:
    - `calabash-ios download`
    - Use Finder to open the folder that contains `calabash.framework`.
    - Drag `calabash.framework` from Finder into your project's  `Frameworks` folder in Xcode.
        * **Make sure that**
            1. `Copy items into destination group's folder (if needed)` *is checked* and 
            2.  _only_ your "-cal " target is checked in `Add to targets`.

      ![Linking with calabash.framework](documentation/images/Frameworks.png "Linking with frameworks")
    - You must also link you -cal target with `CFNetwork.framework` (unless your production target
      is  already linking with `CFNetwork`). To do this click on your -cal target in XCode. Click on 
      Build Phases, expand Link Binary with Libraries, click `+` to add `CFNetwork.framework`.


* Step 3/3: cal-Target Build Settings
 - Click on your project and select your new "-cal" target.
 - Select "Build Settings".
 - Ensure that "All" and not "Basic" settings are selected in "build settings".
 - Find "Other Linker Flags" (you can type "other link" in the search field).
 - Ensure that "Other linker flags" contains: `-force_load "$(SRCROOT)/calabash.framework/calabash" -lstdc++`

*Note*: Now that you have created a separate target, new files that you add to your project are not automatically added to your -LP target. Make sure that any new files you add to your production target are also added to your -LP target.


This screenshot is a reference for you build settings.

![Build settings](documentation/images/linker_flags.png "Build settings")


### Test that `calabash.framework` is loaded.

Make sure you select your "..-cal" scheme and then run you app on 4.x/5 simulator.

Verify that you see console output like

    2012-01-19 LPSimpleExample[4318:11603] Creating the server: <HTTPServer: 0x7958d70>
    2012-01-19 LPSimpleExample[4318:11603] HTTPServer: Started HTTP server on port 37265
    2012-01-19 LPSimpleExample[4318:13903] Bonjour Service Published: domain(local.) type(_http._tcp.) name(Calabash Server)


Branches
========

Some important news about what is happening with Calabash iOS and upcoming features. This is a preliminary notice to keep everyone informed. Soon, there will be a longer blog post at http://blog.lesspainful.com/ explaining more about rationale etc.

### The 0.9.x line
[Link to master branch](https://github.com/calabash/calabash-ios/tree/master).

We've been making many small releases marked as 0.9.xyz for some time. This has been mostly bug-fixes and adding high-level functions, although some releases have added new features too. My current focus has been providing an implementation of 'query' on Calabash Android, and as this is finishing off, I'll turn attention back to Calabash iOS.

Calabash iOS is moving towards what we will designate a 1.0.0 release. What we mean by '1.0.0', is that we consider Calabash a stable and reliable product with a decent feature set sufficient for testing most iOS applications. The label '1.0.0' will mean a much stronger adherence to backwards compatibility, quality and stability. Particularly, from version 1.0.0, Calabash will be adhering to the notion of Semantic Versioning: http://semver.org/, and we will use also continuous integration and automated testing on Calabash (iOS and Android) itself.

But 1.0.0 won't be the next line of releases. There will be a 0.10.x line first which will incorporate significant changes.

The single most significant change in the 0.10.x line will be that Calabash will be supplied as a 'plugin' to the [Frank project](https://github.com/moredip/Frank). Many of the original reasons for creating a separate project for Calabash have now vanished, and only a single remains (the license of Frank, and this is being changed).

*Why?*

- Calabash and Frank share so much infrastructure, and there is no longer a reason to have the work duplicated in two project. By working together both projects will benefit and increase velocity.

- Frank comes with a very cool tool called Symbiote which gives a visual representation of the current screen elements as well as a playground for exploring queries. Calabash iOS (and later Android) users will get access to Symbiote.

- The Frank build system has improved vastly in the past year and has surpassed that of Calabash iOS.

- Calabash also brings benefits to Frank users: the Calabash selector engine features selection into web views, selection by NSPredicate, selection by indexPath, better reflective method-call support. The Calabash touch engine allows synthesizing arbitrary gestures, even those not predefined by UIAutomation. Also, a bunch of other things like 'external' UIAutomation support will exist in the 0.10.x line.

- Cross-pollination of communities.

### What Does This Mean for Calabash users?

A lot of very good things :)  In short, it will mean more features, better error messages and a more slick setup and update experience. The 0.10.x line will work at ensuring that 0.9.x Calabash tests still work with no or only minor migration needed. The 1.0.x line will be a tried and stable version of the 0.10.x line, with focus on more features.

It is our goal that your current tests should still work on the 0.10.x line. If we discover things that cannot be fixed in a backwards compatible manner, we will try hard to supply a migration path.


Updating
========

If you are already using Calabash iOS in a project and you want to update to the latest version, this is very simple.

[Updating your Calabash iOS version](https://github.com/calabash/calabash-ios/wiki/B1-Updating-your-Calabash-iOS-version)


Important notice
================

The Calabash framework uses private Apple APIs to synthesize touch
events. This means that you should double check that `calabash.framework`
is not included in the .ipa file you submit to App Store.
This is usually done by creating a separate build configuration or target
for the version of your app running calabash tests.

An experimental check can be done by the calabash-ios tool

```
    calabash-ios check PATH_TO_IPA_OR_APP
```

This is not guaranteed to work; it is your responsibility to ensure that the framework is properly installed.


Installation details
====================

If you're interested in what's going on you can read the installation details here.

How does automated setup work?
==============================

Verify that you have installed calabash-cucumber correctly by running `calabash-ios` from the command line:

```
    $ calabash-ios
    Usage: calabash-ios <command-name> [parameters]
    <command-name> can be one of
        help
         prints more detailed help information.
        gen
         generate a features folder structure.
        setup (EXPERIMENTAL) [opt path]?
         setup your XCode project for calabash-ios
      ...
```

When you run `calabash-ios setup` and answer any questions it might ask the following happens:

Note that calabash-ios will backup your project file:

    $ calabash-ios setup
    Checking if Xcode is running...
    ----------Info----------
    Making backup of project file: ~/sample/sample.xcodeproj/project.pbxproj
    ...

The project file is copied to `project.pbxproj.bak`. In case something goes wrong you can move this file back to `project.pbxproj` (in your .xcodeproj) folder.

Setup will modify your xcode project file to use `calabash-ios`. You should now have a new Scheme named [target]-cal in Xcode:

![-cal scheme](documentation/images/scheme.png "-cal scheme")


`calabash-ios setup` does the following:

- creates a new -cal target as a copy of your primary target
- add the calabash.framework to your Frameworks folder
- add $(SRCROOT) to framework search path (for that target)
- link with calabash.framework (for that target)
- link with Apple's CFNetwork.framework (for that target)
- set the special `-force_load` and `-lstdc++` linker flags (for that target)


Next steps
==========

Move on to the [Getting started guide](https://github.com/calabash/calabash-ios/wiki/01-Getting-started-guide).

License
=======
calabash-cucumber
Copyright (c) LessPainful APS. All rights reserved.
The use and distribution terms for this software are covered by the
Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
which can be found in the file epl-v10.html at the root of this distribution.
By using this software in any fashion, you are agreeing to be bound by
the terms of this license.
You must not remove this notice, or any other, from this software.




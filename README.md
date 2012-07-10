Welcome to Calabash for iOS
===========================

Calabash is an automated testing technology for Android and iOS native and hybrid applications.
This repository contains support for iOS, for Android, see [Calabash Android](https://github.com/calabash/calabash-android).

This document explains how to install Calabash. For introductory information about the rationale behind Calabash see

[Introducing Calabash](http://blog.lesspainful.com/2012/03/07/Calabash/).



This guide explains how to setup and use Calabash for iOS
=========================================================

After completing this guide you will be able to run tests locally
against the iOS Simulator. You can also interactively explore and
interact with your application using the Calabash console.

Finally, you will be able to test your app on real, non-jailbroken iOS
devices via [the LessPainful service](http://www.lesspainful.com/). 

If you have any questions on Calabash iOS, please use the google group

[http://groups.google.com/group/calabash-ios](http://groups.google.com/group/calabash-ios)

This guide was writting using XCode 4.3, but should also work for
XCode versions >= 4.0.

*NOTE about Xcode 4.3* after upgrading to Xcode 4.3, I needed to install the command line tools from 
the preferences pane under "Downloads" in Xcode. Then I had to do

    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer


Installation
------------

### Prerequisites

You need to have Ruby installed. This is installed by default on MacOSX. 
Verify by running `ruby -v` in a terminal - it should print "ruby 1.8.7" (or higher).

### Fast track

Note: Fast track is EXPERIMENTAL, but in my experience it works for most iOS projects. 
But there *are* some project setups where it does not. 

If it doesn't work in your project, you should read the section "Manual setup with Xcode" below.

For automatic setup: 

1. In a terminal, go to your iOS project
  - `cd path-to-my-ios-project` (i.e. directory containing .xcodeproj file)

2. Install calabash-cucumber gem (this make take some time because of dependencies)
  - `gem install calabash-cucumber`
  - (Note you may need to run `sudo gem install calabash-cucumber` if you get
     ERROR:  While executing gem ... (Gem::FilePermissionError)).

3. Setup your project for Calabash-iOS.
  - `calabash-ios setup`
  (Answer the questions and read the output :)

4. Generate a skeleton features folder for your tests
  - `calabash-ios gen`
  (this also copies the scripts irb_iosX.sh for "interactive development" into your current dir)

5. In Xcode, build your project using the <project-name>-cal scheme
  - ![-cal scheme](calabash-ios/raw/master/documentation/images/scheme.png "-cal scheme")

6. Run the generated test!
  - `cucumber`

If all goes well, you are now ready to write your first test.
Start by editing the file `features/my_first.feature`.

Proceed by reading details about installation below, or moving on to the
[Getting started guide](https://github.com/calabash/calabash-ios/wiki/00-Calabash-iOS-documentation).

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
 - Download the latest version of calabash-ios at
 [https://github.com/calabash/calabash-ios/downloads](https://github.com/calabash/calabash-ios/downloads).
 - Unzip the file.
 - Use Finder to open the folder that contains `calabash.framework`.
 - Drag `calabash.framework` from Finder into you project's
   `Frameworks` folder in Xcode.
   Make sure that (i) `Copy items into
   destination group's folder (if needed)` *is checked* and (ii) _only_
   your "-cal " target is checked in `Add to targets`.
![Linking with calabash.framework](calabash-ios/raw/master/documentation/images/Frameworks.png "Linking with frameworks")

 - You must also link you -cal target with `CFNetwork.framework`
   (unless your production target is already linking with
   `CFNetwork`). To do this click on your -cal target in XCode. Click
   on Build Phases, expand Link Binary with Libraries, click `+` to
   add `CFNetwork.framework`.


* Step 3/3: cal-Target Build Settings
 - Click on your project and select your new "-cal" target.
 - Select "Build Settings".
 - Ensure that "All" and not "Basic" settings are selected in "build settings".
 - Find "Other Linker Flags" (you can type "other link" in the search field).
 - Ensure that "Other linker flags" contains: `-force_load "$(SRCROOT)/calabash.framework/calabash" -lstdc++`

*Note*: Now that you have created a separate target, new files that you add to your project are not automatically added to your -LP target. Make sure that any new files you add to your production target are also added to your -LP target.


This screenshot is a reference for you build settings.

![Build settings](calabash-ios/raw/master/documentation/images/linker_flags.png "Build settings")


### Test that `calabash.framework` is loaded.

Make sure you select your "..-cal" scheme and then run you app on 4.x/5 simulator.

Verify that you see console output like

    2012-01-19 LPSimpleExample[4318:11603] Creating the server: <HTTPServer: 0x7958d70>
    2012-01-19 LPSimpleExample[4318:11603] HTTPServer: Started HTTP server on port 37265
    2012-01-19 LPSimpleExample[4318:13903] Bonjour Service Published: domain(local.) type(_http._tcp.) name(Calabash Server)


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

    calabash-ios check PATH_TO_IPA_OR_APP
    
But this is not guaranteed to work, and it is your responsibility to ensure.    


Installation details
====================

If you're interested in what's going on you can read the installation details here.

How does automated setup work?
==============================

Verify that you have installed calabash-cucumber correctly by running `calabash-ios` from the command line:

    krukow:~/tmp/sample$ calabash-ios
    Usage: calabash-ios <command-name> [parameters]
    <command-name> can be one of
        help
         prints more detailed help information.
        gen
         generate a features folder structure.
        setup (EXPERIMENTAL) [opt path]?
         setup your XCode project for calabash-ios
      ...

When you run `calabash-ios setup` and answer any questions it might ask the following happens:

Note that calabash-ios will backup your project file:

    krukow:~/tmp/sample$ calabash-ios setup
    Checking if Xcode is running...
    ----------Info----------
    Making backup of project file: /Users/krukow/tmp/sample/sample.xcodeproj/project.pbxproj
    ...

The project file is copied to `project.pbxproj.bak`. In case something goes wrong you can move this file back to `project.pbxproj` (in your .xcodeproj) folder.

Setup will modify your xcode project file to use Calabash iOs. You should now have a new Scheme named [target]-cal in Xcode:

![-cal scheme](calabash-ios/raw/master/documentation/images/scheme.png "-cal scheme")


`calabash-ios setup` does the following:

- creates a new -cal target as a copy of your primary target
- add the calabash.framework to your Frameworks folder 
- add $(SRCROOT) to framework search path (for that target)
- link with calabash.framework (for that target)
- link with Apple's CFNetwork.framework (for that target)
- set the special `-force_load` and `-lstdc++` linker flags (for that target)



Next steps
==========

Move on to the [Getting started guide](https://github.com/calabash/calabash-ios/wiki/00-Calabash-iOS-documentation).

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

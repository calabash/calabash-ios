This guide explains how to setup and use Calabash for iOS
=========================================================

After completing this guide you will be able to run tests locally
against the iOS Simulator. You can also interactively explore and
interact with your application using the Calabash console.

Finally, you will be able to test your app on real, non-jailbroken iOS
devices via [the LessPainful service](http://www.lesspainful.com/). Also checkout [Calabash Android](https://github.com/calabash/calabash-android).

If you have any questions on Calabash iOS, please use the google group

[http://groups.google.com/group/calabash-ios](http://groups.google.com/group/calabash-ios)

This guide was writting using XCode 4.2, but should also work for
XCode versions >= 4.0.

Preparing your application.
---------------------------

To use Calabash for iOS in your app, you must do two things: link with
our framework: `calabash.framework`, and install a ruby gem as
described below. (You also need to link with Apple's CFNetwork
framework if you are not already using this.)

Installation
------------

### Prerequisites

You need to have Ruby installed. This is installed by default on MacOSX. 
Verify by running `ruby -v` in a terminal - it should print "ruby 1.8.7".

You may want to install Ruby 1.9.2+ and a recent RubyGems version.
I use rbenv to manage my Ruby installations.

For rbenv, see:

 [https://github.com/sstephenson/rbenv](https://github.com/sstephenson/rbenv)


Fast track
============
Note: Fast track installation works for most iOS projects, but there are some project setups where it does not. If it doesn't work in your project, you should read the section "Manual setup with Xcode" below.

Note: If you are an existing user of Calabash iOS, don't run setup. Instead you can update to the latest version by running.
`gem update calabash-cucumber` and from your project directory (containing calabash.framework) run `calabash-ios download`.

Otherwise, follow these steps:

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

5. In Xcode, build your project using the <project-name>-cal scheme
  - ![-cal scheme](calabash-ios/raw/master/documentation/images/scheme.png "-cal scheme")

6. Run the generated test!
  - `cucumber`

If all goes well, you are now ready to write your first test.
Start by editing the file `features/my_first.feature`.

Proceed by reading details about installation below, or moving on to the
[Getting started guide](https://github.com/calabash/calabash-ios/wiki/00-Calabash-iOS-documentation).

Important notice
================

The Calabash framework uses private Apple APIs to synthesize touch
events. This means that you should double check that `calabash.framework`
is not included in the .ipa file you submit to App Store.
This is usually done by creating a separate build configuration or target
for the version of your app running calabash tests.

Installation details
====================

If fast track setup doesn't work for you, or you're interested in
what's going on you can read the installation details here.

There are two primary ways of linking with the framework. Either you
can create a whole separate target by duplicating your production
target from Xcode. Alternatively you can create a special build
configuration for your existing target. The second option is easiest
to maintain and setup, but there are some situations where it cannot
be used. Particularly, you must ensure you are not accidentally
loading `calabash.framework` which may happen if you use `-all_load`
or `-ObjC` linker options. In this case you must make a separate target for calabash (see Manual setup with Xcode below).

### Ruby and calabash-cucumber gem.

*   Make sure ruby and ruby gems is on your path.

        krukow:~/examples$ ruby -v
        ruby 1.9.2p290 (2011-07-09 revision 32553) [x86_64-darwin11.1.0]
        krukow:~/examples$ gem -v
        1.8.10

*   Install the `calabash-cucumber` gem.

        krukow:~$ gem install calabash-cucumber
        Successfully installed calabash-cucumber-0.9.23
        1 gem installed
        Installing ri documentation for calabash-cucumber-0.9.23...
        Installing RDoc documentation for calabash-cucumber-0.9.23...


You now have two options: automated setup using the `calabash-ios`
tool or manual setup. Both are described below.

Automated setup using the calabash-ios tool
===========================================

Verify that you have installed calabash-cucumber correctly by running `calabash-ios` from the command line:

    krukow:~/tmp/sample$ calabash-ios
    Usage: calabash-ios <command-name> [parameters]
    <command-name> can be one of
        help
         prints more detailed help information.
        gen
         generate a features folder structure.
        setup (EXPERIMENTAL) [opt path]?
         setup your XCode project for calabash-ios)
      ...

Make sure you are in the directory containing your project.
Then run `calabash-ios setup` and answer any questions it might ask :)

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

- add the calabash.framework to your Frameworks folder
- add $(SRCROOT) to framework search path
- link with calabash.framework (target can be chosen)
- link with Apple's CFNetwork.framework
- create a new Build configuration: Calabash
- ensure calabash.framework is loaded in Calabash configuration
- create a new scheme name <project>-cal. This scheme launches
the Calabash configuration for your target

Note that `calabash.framework` is added to your target, but only
forced to load in the Calabash build configuration. Hence it is
stripped from your other build configurations. But this stripping only
occurs if you don't force the load by other means such as setting
Other Linker Flags: `-ObjC` or `-all_load`. It is your responsibility
to ensure that you are not loading `calabash.framework` in the app you
submit to App Store.


Manual setup with Xcode
=======================

Instructions:

* Step 1/3: Duplicate target.
 - Select your project in XCode and select your production target for your app.
 - Right click (or two-finger tap) your target and select "Duplicate target"
 - Select "Duplicate only" (not transition to iPad)
 - Rename your new target from ".. copy" to "..-cal"
 - From the menu select Edit Scheme and select manage schemes.
 - Rename the new scheme from ".. copy" to "..-cal"

* Step 2/3: Link with framework.
 - Download the latest version of calabash-ios at
 [https://github.com/calabash/calabash-ios/downloads](https://github.com/calabash/calabash-ios/downloads).
 - Unzip the file.
 - Use Finder to open the folder that contains `calabash.framework`.
 - Drag `calabash.framework` from Finder into you project's
   `Frameworks` folder in Xcode.
   Make sure that (i) `Copy items into
   destination group's folder (if needed)` is checked and (ii) _only_
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


You should now be able to explore Calabash.


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

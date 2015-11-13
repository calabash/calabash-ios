## Calabash iOS Environment Variables

Calabash iOS references Unix environment variables to control its runtime behavior.

The behavior of a variable might differ from across Xcode or iOS versions.  Please read the documentation  carefully.

## Deprecated Variables

New versions of Xcode and iOS often require new environment variables or require that existing environment variables become deprecated.  Please note your Xcode and iOS versions and read the following deprecated variables section carefully.

### Deprecated Xcode 6.0

* `CALABASH_FULL_CONSOLE_OUTPUT`
* `DETECT_CONNECTED_DEVICE`

### Deprecated Xcode 5.1

* `SDK_VERSION`
* Setting `DEVICE_TARGET` to `device` or `simulator` has been deprecated.

**Note** The `NO_LAUNCH` variable is still supported in Xcode >= 5.1, but it is almost never correct to set this variable.  See the docs below.

### Deprecated Xcode 4.6.3

* `LAUNCH_VIA`

### Deprecated iOS > 5

* `OS`

### Deprecated LessPainful (pre April 2013)

* `NO_DOWNLOAD`
* `NO_BUILD`
* `NO_GEN`
* `SUBMIT_URL`
* `http_proxy`

## Conventions

Variables that take boolean values should be passed as `0` or `1`, _not_ as `true` or `false`.

#### Example: Turn on verbose logging.

```
DEBUG=1      # Correct!
DEBUG=true   # Incorrect.
```

Paths or values with spaces need double or single quotes.

#### Example: Quoting values with spaces.

```
APP_BUNDLE_PATH="Users/adamant/path with/a spaces/in it"   # Correct!
APP_BUNDLE_PATH=Users/adam ant/path with/a spaces/in it     # Incorrect.

DEVICE_TARGET='iPhone Retina (3.5-inch) - Simulator - iOS 7.1'  # Correct!
DEVICE_TARGET=iPhone Retina (3.5-inch) - Simulator - iOS 7.1    # Incorrect.
```

## Environment Variables

### `APP` and `APP_BUNDLE_PATH`

***iOS Simulator testing only.***

`APP_BUNDLE_PATH` and `APP` are synonyms; use either, but not both.

Use this variable to tell calabash where it can find the the application bundle (AKA app bundle).

This is only used for simulator testing.  It is ignored when testing on devices.

Calabash can usually automatically set this variable if an Xcode project is located in the directory where you call `calabash-ios console` or `cucumber` from.

#### Example

```
APP=./build/calabash/Briar-cal.app cucumber
```

### `BUNDLE_ID`

***Device testing only***

The bundle identifier of the app you are testing.

When testing against a device this is a _required_ variable.

Do not set this variable when testing against simulators.

#### Example

```
BUNDLE_ID="com.example.FlappyMonkey-cal"
```

### `DEVICE`

This variable controls which recordings to playback when using the record/playback API.  There are two possible values: `ipad` and `iphone`; each form factor has different recording.

If you are testing iOS >= 7, you cannot use the record/playback API; it is no longer supported by Apple.

**NOTE:** The record/playback API is slated for deprecation.

#### Special

If your app is a iPhone app that is emulated on an iPad, you should use `DEVICE=iphone`.


#### Example

```
DEVICE=iphone
DEVICE=ipad
```

### `CALABASH_FULL_CONSOLE_OUTPUT`

Use this variable to enable more verbose logging.

This variable will be deprecated in Xcode 6.0 / Calabash 0.11.0.

### `CALABASH_IRBRC`

Use this variable to load a custom .irbrc when opening calabash-ios console.  This is useful if you have multiple calabash projects and want to share an .irbrc across all of them.

#### .irbrc load order rules

1. If `CALABASH_IRBRC` is defined, then that .irbrc is loaded.
2. If there is a .irbrc in the directory where `console` is called, then that file is loaded.
3. Otherwise, the defaults scripts/.irbrc is loaded.

#### Special

Calling `calabash-ios console` sets the `IRBRC` environment variable.

#### Example

```
$ CALABASH_IRBRC="~/.irbrc-calabash" calabash-ios console
```

### `CALABASH_NO_DEPRECATION`

Calabash deprecation warnings getting you down?  Use this variable to turn off deprecation warnings.

It is not recommended that you turn off deprecation warnings. One morning you will wake up and find that everything is broken; it will make you grumpy.

#### Example

```
CALABASH_NO_DEPRECATION=1 cucumber
```

#### Pro Tip: Read the deprecation warnings.

Read the deprecation warnings for the replacement API.


### `DEBUG`

Set this variable to `1` to enable verbose logging.

#### Example

```
DEBUG=1 cucumber
```

#### Pro Tip: Reduce console spam from third-party gems.

If you are seeing a bunch of spam from tools like bundler you should unset this variable.

```
shell: unset DEBUG
 ruby: ENV.delete('DEBUG')
```

### `DEBUG_HTTP`

If you find yourself in the unfortunate position of needing to see more details about the http traffic between your app and calabash, you can set this variable to `1`.

#### Example

```
DEBUG_HTTP=1 cucumber
```

### `DEVICE_ENDPOINT`

The ip and port of the embedded calabash server.

When testing against a device this is a ***required*** variable.

When testing against simulators, you ***should not*** set this variable.

You can find your device's ip address using the Settings.app on your device.

```
Settings.app > Wi-Fi > your network > disclosure button
```

#### Example

```
DEVICE_ENDPOINT=http://10.0.1.3:37265    # Correct!
DEVICE_ENDPOINT=http://10.0.1.3          # Incorrect.
```

#### Special

You cannot change the calabash port.

#### Pro Tip:  Name your device.

If you name your device, you can often create a stable URL.

```
DEVICE_ENDPOINT=http://saturn.local:37265
```

### `DEVICE_TARGET`

A device UDID, simulator name, or CoreSimulator UDID.

When testing against a device this is a _required_ variable.

When testing against simulators on Xcode >= 5.1, use this variable to indicate which simulator to launch.

If the `DEVICE_TARGET` is not set, calabash will attempt to discover whether or not you are trying to target a device or a simulator.

#### Defaults: Simulator

If `APP_BUNDLE_PATH` is set, the target is assumed to be a simulator.  These are the default simulators based on the Xcode version:

```
       Xcode > 6.0  ==> 'iPhone 5 (8.0 Simulator)'
5.1 <= Xcode < 6.0  ==> 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
       Xcode < 5.1  ==>  the last simulator that was opened
```

#### Defaults: Devices

If `BUNDLE_ID` is set, the target is assumed to be a device.  Calabash will try to discover a connected device.  If you have more than one device connected, you _must_ use the `DEVICE_TARGET` to tell calabash which device to target.

**Note:** Even if you only have one device connected, we recommend that you _always_ set this variable when targeting a device.

#### Special

On Xcode < 5.1, this variable was only used when testing against physical devices.

#### Example: Targeting a device.

```
DEVICE_TARGET=6c3ed5431b5dfc29758f8a35644b35bd435bdfe2 cucumber
```

#### Example: Targeting a simulator.

```
# Xcode > 6.0 - using a simulator name
DEVICE_TARGET='iPhone 5s (8.0 Simulator)' cucumber

# Xcode > 6.0 - using a simulator UDID
DEVICE_TARGET='D619B029-17F3-476C-8ADE-507DD356A27F' cucumber

# 5.1 <= Xcode < 6.0
DEVICE_TARGET='iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1' cucumber
```

#### Pro Tip: Available devices.

On Xcode >= 5.1, you can find the available simulators and devices using the `instruments` program.

```
instruments -s devices
```

#### Pro Tip: Device UDIDs should be private.

Device UDIDs should be private.  When posting debug output on the web, do not post un-obscured device UDIDs.

### `NO_LAUNCH`

***It is almost always incorrect to set NO_LAUNCH=1.***

Use this to control whether or not calabash launches your app.

If you are testing against iOS >= 7, **you must not set this to 1**; calabash must be allowed to launch your app with instruments to have access to the UIAutomation API.

As of Xcode >= 5.1 there is almost never a good reason to use this variable.  It is only _necessary_ for testing against iOS 5.1.1 which cannot be targeted by instruments.

Once iOS 5.1.1 support is dropped, this variable _will be deprecated._

### `NO_STOP`

Use this to control whether or not calabash will exit your application after the cucumber tests have completed.

Here is an example Cucumber After hook.

```
After do |scenario|
  launcher = Calabash::Cucumber::Launcher.new
  unless launcher.calabash_no_stop?
    calabash_exit
    launcher.stop
  end
end
```

If `NO_STOP=1`, then `calabash_exit` and `launcher.stop` will _not_ be called and your application will remain running after Cucumber finishes.  This variable is commonly used with {Calabash::Cucumber::Core#console_attach} to debug failing Scenarios.

#### Pro Tip:  Use NO_STOP=1, console_attach, and the @wip tag to debug failing Scenarios.

When debugging a failing Scenario, use `NO_STOP=1` to prohibit calabash from exiting your application, open a console, call `console_attach`, and explore your application from the command line.

```
1. Tag your failing Scenario with @wip (Work in Progress).
2. Run just that Scenario.
   $ NO_STOP=1 bundle exec cucumber -t @wip
3. When it fails, the application will remain open.
4. Open a console and call console_attach
   $ bundle exec calabash-ios console
   > console_attach
5. Perform queries and gestures in the console to figure out why the Scenario failed.
```

### `PLAYBACK_DIR`

***Available only for iOS < 7.0.***

The directory where your recordings can be found.

#### Rules for Locating Recordings

1. if PLAYBACK_DIR is defined, look there first
2. then features/
3. then features/playback
4. finally fall back to the recordings provided by the gem.

**NOTE:** The record/playback API is slated for deprecation.

#### Special

If you are testing iOS >= 7, you cannot use the record/playback API; it is no longer supported by Apple.
The default value is features/playback.

### `PROJECT_DIR`

You do not normally need to set this value.  Use it only if you a non-standard directory layout.  Calabash will tell you if it cannot find your project.

#### Example

```
PROJECT_DIR='/path/to/your/app.xcodeproj directory'
```

### `RESET_BETWEEN_SCENARIOS`

***The behavior of this variable differs depending on test platform.  Read this carefully.***

Use this variable to reset your app's sandbox between cucumber Scenarios.

Outside of the Xamarin Test Cloud, it is not possible to reset an app's sandbox on physical devices.  The app must be deleted and re-installed.  Calabash cannot delete .ipas from or deploy .ipas to physical devices.

When testing locally on physical devices, this variable is ignored.

To recap:

1. You can use this variable when targeting simulators.
2. You can use this variable when testing on the Xamarin Test Cloud.
3. This variable is ignored during local testing against physical devices.

#### Pro Tip:  Reset the app sandbox before certain Scenarios.

Use a `Before` hook + a `tag` to control when calabash will reset the app sandbox.

See this Stack Overflow post: http://stackoverflow.com/questions/24493634/reset-ios-app-in-calabash-ios

### `SCREENSHOT_PATH`

Use this variable to apply a 'prefix' to a screenshot when saving.  See the examples.

#### Note

The behavior of this variable is subject to change.

#### Special

If the the *path* portion of SCREENSHOT_PATH does not exist, `screenshot` will raise an error.

@see {Calabash::Cucumber::FailureHelpers#screenshot}

#### Example: Specify a prefix

```
SCREENSHOT_PATH=ipad_                   => ipad_screenshot_0.png
SCREENSHOT_PATH="screenshots/iphone5s-" => screenshots/iphone5s-screenshot_0.png
```

#### Example: Specify a directory

```
# correct!
SCREENSHOT_PATH=/path/to/a/directory/ => path/to/a/directory/screenshot_0.png
# incorrect :(
SCREENSHOT_PATH=/path/to/a/directory  => path/to/a/directoryscreenshot_0.png
```

### `SDK_VERSION`

***iOS Simulator testing only.***

Deprecated in Xcode >= 5.1

Used to indicate which simulator to launch on Xcode < 5.1.

#### Example

```
SDK_VERSION=6.1 cucumber
```

## Variables for Predefined Steps

Using the predefined steps is not recommended; they are provided as a way of introducing BDD concepts, cucumber, gherkin, and calabash.  Every project should cultivate its own vernacular - a shared language
between developers, clients, and users.

There is an internal debate about whether or not deprecate  the predefined steps.

Outside of the predefined steps, these variable have no effect.

### `WAIT_TIMEOUT`

If you are using the calabash predefined steps, you can use this variable to globally control the timeout for the `wait_*` methods.

Defaults to 30 seconds.

#### Pro Tip: Enforce a global wait timeout.

It is good idea to set a global timeout for your project and to never deviate from that timeout without documenting why.  A common bad practice is to fix failing tests by increasing the timeout.  This slows down the tests and hides bugs.  In practice, a 14 second wait time is recommended.

### `STEP_PAUSE`

If you are using the calabash predefined steps, you can use this variable to globally control how long to `sleep`.

Defaults to 0.5 seconds.

#### Pro Tip: Avoid sleeps.

You should avoid `sleep` whenever possible.  You should always prefer to `wait` for something and then proceed.  Waiting has the advantage that you only ever wait as long as you need to, which optimizes test run times.

#### Pro Tip: Enforce a global sleep value.

There are times when sleep cannot be avoided.   It is very good idea to set a global sleep value and to never deviate from that value without documenting why.  A common bad practice is to fix failing tests by
increasing sleep times.  This slows down the tests and hides bugs.

* @see {Calabash::Cucumber::WaitHelpers#wait_tap}
* @see {Calabash::Cucumber::WaitHelpers}

## Variables for Gem Developers

These variables are reserved for gem developers.  Normal users should not set alter these variables.

### `CALABASH_NO_DYLIBS`

Use this variable to control whether or not the rake `build_server` task should try to build the calabash dynamic libraries (dylibs).  Dylibs require inserting .xcspec files directly into the Xcode.app bundle, which is not something every user wants to do.  The default behavior is to try to build the dylibs.

### `CALABASH_SERVER_PATH`

Use this variable to tell the rake `build_server` task to where your calabash-ios-server repository is located.  By default, the task expects the server sources to be located two directories up in a directory named `calabash-ios-server`.

#### Example

```
$ cd calabash-ios/calabash-cucumber
$ tree -d -L 1 ../../calabash-ios-server
../../calabash-ios-server
```

### `CALABASH_VERSION_PATH`

This variable should be deprecated.

The http 'version' route.

Unless you are gem or server dev, don't set this.

### `CONNECT_TIMEOUT` and `MAX_CONNECT_RETRY`

How long to wait for giving up connecting to the embedded calabash server.

Increasing these values will probably not fix the problem you are having. :(

`MAX_CONNECT_RETRY` and `CONNECT_TIMEOUT` are tightly coupled.  The default is try to reconnect once every 3 seconds 10 times for a total of 30 seconds.

#### Defaults

```
MAX_CONNECT_RETRY ==> 10
  CONNECT_TIMEOUT ==> 3
```

#### Pro Tip: Fail fast during development.

If you are going to fail, doing it sooner is better than waiting.  Decrease both of these values during gem development.

### `DETECT_CONNECTED_DEVICE`

This variable should be deprecated.

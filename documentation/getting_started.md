Getting started guide
---------------------

Exploring the sample application (or your app).
-----------------------------------------------

Start your app with the -LP target in simulator.  Alternatively if you
want to start with the sample app, make sure you clone the git
repository and open the LPSimpleExample project in the `examples`
folder.

### Run it
CMD-R to run. Look at the log output and verify that you see:

    LPSimpleExample[11298:13703] HTTPServer: Started HTTP server on port 37265

If that message is there, you're good to go.

### Writing tests.

Test are run using [Cucumber](http://cukes.info/) and written in a
special and particularly readable language: Gherkin.

In your project directory you can run the following command to setup a test directory.

    krukow:~/tmp/test$ calabash
    I'm about to create a subdirectory called features.
    features will contain all your calabash tests.
    Please hit return to confirm that's what you want.

    <RETURN>

    features subdirectory created. Try starting you app in the iOS simulator
    using the Calabash/-LP target.

    Then try executing

    STEP_PAUSE=2 OS=ios5 DEVICE=iphone cucumber

    (replace ios5 with ios4 if running iOS 4.x simulator.
    Replace iphone with ipad if running iPad simulator.).

This generates a features directory containing a single test that
simply takes a screenshot.

Try running it with cucumber (`OS=ios4` if running iOS 4).

    krukow:~/tmp/test$ STEP_PAUSE=2 OS=ios5 DEVICE=iphone cucumber
    Feature: Running a test
        As an iOS developer
        I want to have a sample feature file
        So I can begin testing quickly

        Scenario: Example steps    # features/my_first.feature:6
          Given the app is running # calabash-cucumber-0.9.2/lib/calabash-cucumber/calabash_steps.rb:6
          Then take picture        # calabash-cucumber-0.9.2/lib/calabash-cucumber/calabash_steps.rb:165
          Saved screenshot: screenshot_8.png

    1 scenario (1 passed)
    2 steps (2 passed)
    0m2.036s
    krukow:~/tmp/test$ open screenshot_8.png

To see what steps are available and how they are implemented using the
Ruby API see [Step definition wiki](https://github.com/calabash/calabash-ios/wiki/Predefined,-canned-steps).

Again, please contact `karl@lesspainful.com` with any questions or problems.


### Explore interactively!

A nice way to use calabash is to explore it interactively.
The easy way is to just run one of the irb scripts: `irb_ios4.sh` or
`irb_ios5.sh`. These are included in the `examples` folder in the
[git repo](https://github.com/calabash/calabash-ios).

From this console you can explore your application interactively.

You can query, touch, scroll, etc from the irb session. You'll see how below.

### Query
If you're running the iOS5 iPhone simulator run `irb_ios5.sh` otherwise: `irb_ios4.sh`.
(if you're running iPad edit the appropriate script and change `iphone` to `ipad`).

Notice that the sample app has a button: "Login".
Now try this from the irb:

    ruby-1.9.2-p290 :003 > query("button")

You should see something like this:

    => ["<UIRoundedRectButton: 0x6567e00; frame = (109 215; 73 37); opaque = NO; autoresize = RM+BM; layer = <CALayer: 0x6567ef0>>"]

The `query` function takes a string query as an argument. They query argument is similar to a css selector, for example we can do:

    ruby-1.9.2-p290 :009 > query("button label")
     => ["<UIButtonLabel: 0x6624f40; frame = (16 9; 40 19); text = 'Login'; clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer: 0x6645ec0>>"]

It may also take parameters that are mapped to Objective-C selectors on the found object.

    ruby-1.9.2-p290 :010 > query("button label", :text)
    => ["Login"]

### Touch

Anything that can be found using query can also be touched.
Try this while you watch the iOS Simulator:

    ruby-1.9.2-p290 :011 > touch("button")

Notice that the button is touched (turns blue), although this button doesn't do anything.

You can also touch the tab bars:

    ruby-1.9.2-p290 :016 > touch("tabBarButton index:1")

The filter: `index:1` means that it is the second tab-bar button that should be touched.

### Accessibility

In general UI views are found using accesibility labels. To use those in the simulator they must be enabled.

* Press the "home-screen" button in the iOS Simulator
* Scroll left and open the Settings app insied iOS Simulator
* Select `General` > `Accessibility` > `Accessibility Inspector` : On.
* Re-run the sample app from XCode.

In your irb session try this:

    ruby-1.9.2-p290 :025 > query("view marked:'switch'")

This command finds a view with accessibility label 'switch' (not that we use single quotes to delimit the accessibility label.

In general, many views have accessibility labels that "make sense". For example the tab bar buttons have accessibility labels:

    ruby-1.9.2-p290 :029 > touch("tabBarButton marked:'second'")

To control accessibility labels on your views use:
`isAccessibilityElement = YES, and accessibilityLabel = @"somelbl";` This can be done in interface builder or programmatically:

        (void) viewDidLoad {
            [super viewDidLoad];
            self.uiswitch.isAccessibilityElement = YES;
            self.uiswitch.accessibilityLabel = @"switch";
        }

### Advanced commands

Surprisingly, these commands are enough to navigate fairly many iOS apps. However, there are many more commands available. Consult the [Step definition wiki](https://github.com/calabash/calabash-ios/wiki/Predefined,-canned-steps).

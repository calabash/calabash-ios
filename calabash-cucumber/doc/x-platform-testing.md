# Cross-platform Acceptance Testing Best Practices

Test automation is programming - hence, well-established practices of programming apply to test automation. Ruby is object-oriented, and most Calabash tests should also follow good object-oriented design (e.g., principles of abstraction, separation of concerns, modularity, reuse...).

A well-established pattern in test engineering is the *Page-Object Pattern* (POP). While originating in web testing, the ideas of POP apply equally well to native mobile. In this short article, we'll illustrate how to use the page object pattern to better architect test code and obtain better cross-platform code reuse.

We've created a sample project: [X-Platform-Example](https://github.com/calabash/x-platform-example) using the open source WordPress app. If you want to follow along and try things out, go to the project page [https://github.com/calabash/x-platform-example](https://github.com/calabash/x-platform-example) and follow install and run instructions. You can also choose to just read about the principles in this article and try to implement them in you own app.

LessPainful also provides both on-site and public training courses where we teach the use of Calabash as well as cross-platform and automated testing best practices. If you're interested in a two-day, hands-on course, please contact us at [contact@lesspainful.com](mailto:contact@lesspainful.com).

# Page Objects

A *page object* is an object that represents a single screen (page) in your application. For mobile, "screen object" would possibly be a better word, but Page Object is an established term that we'll stick with.

A page object should abstract a single screen in your application. It should expose methods to query the state and data of the screen as well as methods to take actions on the screen. 

As a trivial example, a "login screen" consisting of username and password text fields and a "Login" button could expose a method `login(user,pass)` method that would abstract the details of entering username, password, touching the "Login" button, as well as 'transitioning' to another page (after login). A screen with a list of talks for a conference could expose a `talks()` method to return the visible talks and perhaps a `details(talk)` method to navigate to details for a particular talk.

The most obvious benefit of this is abstraction and reuse. If you have several steps needing to navigate to details, the code for `details(talk)` is reused. Also, callers of this method need not worry about the details (e.g. query and touch) or navigating to this screen.

# Cross-platform Core Idea


Let's go into more detail with this last example. Consider the following sketch of a class (don't do it exactly like this - read on a bit):

```ruby

    class TalksScreen
       def talks
       # query all talks...
       end
       
       def details(talk)
       #touch talk…
       end
    end
```


Suppose you're building the same app for iPhone and Android phones. Most likely the interface of the `TalksScreen` class makes complete sense on both platforms. This means that the calling code, which is usually in a step definition, is independent of platform - hence it can be reused across platforms. 

Working this way gets you complete reuse of Cucumber features as well as step definitions: the details of interacting with the screen is pushed to page object implementations.

The idea is that you provide an implementation of page objects for each platform you need to support (e.g. iPhone, iPad, Android phone, Android tablet, mobile web, desktop web,…).

# Cross-platform in practice

So… The idea and design looks good. The question now is how to implement this is practice. Here we describe the mechanics and below you'll find an example extracted from [X-Platform-Example](https://github.com/calabash/x-platform-example).

There are a couple of ingredients we need.

1. For each screen you want to automate, decide on an interface for a page object class (e.g. like `TalksScreen` above).
2. Use only custom steps, and in each step definition *only* use page objects and their methods (no direct calls to Calabash iOS or Calabash Android APIs).
3. For each supported platform, define a class with implementations of the page-object methods.
4. Create a Cucumber profile (`config/cucumber.yml`). Define a profile for each platform (e.g. `android` and `ios`), and ensure that the profile *only* loads the page object classes for the platform.
5. Rejoice and profit!

Let's see what these steps look like in a concrete example on the [X-Platform-Example](https://github.com/calabash/x-platform-example).

# Example

## Step 1 - Interface
For the wordpress app, let's focus on the Login/Add-WordPress Blog screen. This method has a single method: `login(user)` which takes a hash `{:email => 'username', :password => 'somepass'}` representing a user:

```ruby

    def login(user)
      #…
    end 
    
    def assert_invalid_login_message()
      #…
    end
```

For this simple screen the interface consists of just these two methods.

## Step 2 - Step definitions

We have a feature alà 

    Scenario: Invalid login to WordPress.com blog
      Given I am about to login
      When I enter invalid credentials
      Then I am presented with an error message to correct credentials

Below are step definitions that *only use the page objects* and no Calabash methods like touch, query…

For the following, assume we have also a Page Object class `WelcomePage` with a method `wordpress_blog` that transitions to the `AddWordPressBlog` screen:

```ruby

    ## Invalid login ##
    Given /^I am about to login$/ do

      welcome = page(WelcomePage).await    
      @page = welcome.wordpress_blog
      
	end

    When /^I enter invalid credentials$/ do
      @page = @page.login(USERS[:invalid])
    end

    Then /^I am presented with an error message to correct credentials$/ do
      @page.assert_invalid_login_message
      screenshot_embed
    end
```

The `page` method is a helper method in Calabash which initializes a page object from a class. The `await` method just returns the page object after waiting for the page to be loaded.

We store the page object in an instance variable in the cucumber world (`@page`) and use it in the subsequent steps.

Notice how the steps only use page-object methods. This feature, as well as the step definitions, can be 100% reused across platforms. Great!

## Step 3 - Platform implementations

Now we need to give an implementation of the `WordPressComPage` on iOS and Android (and all other supported platforms). We put those implementations in separte directories `features/ios/pages` and `features/android/pages` and name them `word_press_com_page_ios.rb` and `word_press_com_android.rb`.

Here is the implementation for iOS. It uses an abstract Page Object Class defined in Calabash iOS (`Calabash::IBase`).

```ruby
require 'calabash-cucumber/ibase'

class WordPressComPage < Calabash::IBase

  def title
    "Sign In"
  end

  def login(user)
     touch("view marked:'Username'")
     await_keyboard

     keyboard_enter_text user[:email]

     touch("view marked:'Password'")

     keyboard_enter_text user[:password]
     done

     wait_for_elements_do_not_exist(["tableViewCell activityIndicatorView"],
                                    :timeout => 120)


     if element_exists(invalid_login_query)
      self
     else
      page(MainPage).await
     end
  end

  def assert_invalid_login_message
    check_element_exists(trait)
    check_element_exists(invalid_login_query)
  end

  def invalid_login_query
    "label {text LIKE '*Sign in failed*'}"
  end

end

```

And for Android:

```ruby
class WordPressComPage < Calabash::ABase

  def trait
    "* id:'username'"
  end

  def await(opts={})
    wait_for_elements_exist([trait])
    self
  end


  def login(user)
    query("* id:'username'",{:setText => user[:email]})
    query("* id:'password'",{:setText => user[:password]})

    performAction('scroll_down')

    touch(login_button_query)

    sleep(1)#Chance to show Dialog

    wait_for(:timeout => 60, :timeout_message => "Timed out logging in") do
      current_dialogs = query("DialogTitle",:text)

      empty_dialog = current_dialogs.empty?
      error_dialog = current_dialogs.include?("Error")
      no_network_dialog = current_dialogs.include?("No network available")

      empty_dialog or error_dialog or no_network_dialog
    end

    main_page = page(MainPage)

    if main_page.current_page?
      main_page.await
    else
      self
    end
  end

  def invalid_login_query
    login_button_query
  end

  def login_button_query
    "android.widget.Button marked:'Log In'"
  end

  def assert_invalid_login_message
    check_element_exists(invalid_login_query)
  end


end
```

## Step 4 - Conditional loading

The final missing part is conditionally loading page-object implementations based on which platform we're running. This is done using Cucumber *profiles*. We create a file `config/cucumber.yml` 

    ---
    android: RESET_BETWEEN_SCENARIOS=1 PLATFORM=android -r features/support -r features/android/support -r features/android/helpers -r features/step_definitions -r features/android/pages/

    ios: APP_BUNDLE_PATH=ios-source/3.3.1/build/Applications/WordPress.app RESET_BETWEEN_SCENARIOS=1 PLATFORM=ios -r features/support -r features/ios/support -r features/ios/helpers -r features/step_definitions -r features/ios/pages
    
We're using Cucumbers `-r` option to only load a subset of Ruby files. We can then execute the tests as specified [here](https://github.com/calabash/x-platform-example).

iOS:

    cucumber -p ios features/login.feature
    
Android:

    calabash-android run path_to.apk -p android features/login.feature
    
## Conclusion

We've described how to improve the architecture of your test code base: using page objects you get better abstraction, reuse and cross-platform comes more easily. We've created an open source sample project that you can use for inspiration: [X-Platform-Example](https://github.com/calabash/x-platform-example).

Comments and improvements welcome!

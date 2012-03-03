Predefined steps in Calabash iOS
=================================

Predefined steps give you a fast and easy way to start testing your
app without having to do any programming. But please remember that
Calabash is not limited to the steps defined in this document. You can
write your own, so called, "custom steps". Using custom steps,
Calabash iOS is able to synthesize most touch events and find most
views. Ideally, the features that describe your app are written with
custom steps that use language of your business domain.

This document gives examples, not the full step definitions. It is a "human readable" description of the step definitions found
in the file `calabash_steps.rb` `(calabash-cucumber\lib\calabash-cucumber\calabash_steps.rb)`.

You can easily generalize the examples. For example, `Then I touch the "login" button` can have any string in quotes, not just "login".

Also note that most steps find views by their accessibility
labels. This means that for the tests to work, you must enable
accessibility on the simulator or phone you are testing on.


If you have any questions, please use the google group

[http://groups.google.com/group/calabash-ios](http://groups.google.com/group/calabash-ios)

Screenshots
----------
You can take a screenshot

    Then take picture

This will generate a .png prefixed with the step number.

Touching (tapping)
---------------------------
Touching arbitrary views by accessibility label:

    Then I touch "accLabel"

Buttons by accessibility label

    Then I touch the "login" button

or by number/index (not number starts with 1 not 0)

    Then I touch button number 1

Input fields (UITextFields). Note, this looks for an UITextField with the placeholder property set to the quoted string.

    Then I touch the "placeholder" input field

Lists (UITableCellView) by number. Note this can only be used to touch visible cells - it doesn't try to scroll down/up.

    Then I touch list item number 1

Switches (UISwitch),

    Then I toggle the switch

this step works if there is a single switch. Otherwise use,

    Then I toggle the "accLabel" switch

where "accLabel" should be the accessibilityLabel for the switch.

Built-in keyboard. Touching the Done/Search button

    Then I touch done
    Then I touch search

Map views.

    Then I touch the user location

Coordinate based touches,

    Then I touch on screen 100 from the left and 250 from the top


Entering text
---------------------------
Note, all these steps work on text fields (UITextField).
Text is entered by setting the text directly on the object. We are thinking about support for entering using the native keyboard.

Calabash uses placeholders for identifying text fields, so `... the "login" input field` means the input field with *placeholder* "login".

Entering text by placeholder:

    Then I enter "text to write" into the "placeholder" input field

alias

    Then I fill in "placeholder" with "text to write"

Text by table (fields are by "placeholder")

    I fill in text fields as follows:
     | field      | text    |
     | Last Name  | Krukow  |
     | Email      | a@b.c   |
     | Username   | krukow  |
     | Password   | 123     |
     | Confirm    | 123     |

Text by input field number:

    Then I enter "text" into input field number 1

Clearing fields (like entering "")

    Then I clear "placeholder"

Clearing fields by number

    Then I clear input field number 1


Waiting
---------------------------
These are usually about waiting to see certain text or ui components. Usually these are identified by their accessibilityLabels, component type (like a navigation bar) or pure text like in a label or a web view.

Waiting for text, or a view with a certain accessibilityLabel

    Then I wait to see "text or label"
    Then I wait for "text or label" to appear

wait for something to disappear

    Then I wait until I don't see "text or label"
    I wait to not see "text or label"

waiting for a button with an accessibilityLabel

    Then I wait for the "login" button to appear

waiting for an iOS navigation bar with a certain title,

    Then I wait to see a navigation bar titled "title"

waiting for a text field

    Then I wait for the "label" input field

waiting for a number of text fields

    Then I wait for 2 input fields

waiting in general

    Then I wait
    Then I wait and wait
    Then I wait and wait and wait...
    Then I wait for 2.3 seconds

(this 2,4, 10 or an arbitrary number of seconds).

Back button
---------------------------
In an iOS navigation bar, you can touch the "back" button using

    Then I go back


Swipes
---------------------------
Swiping an unspecified place (usually when you have big scroll view in the center of the screen). Swipe directions can be left, right, up and down.

    Then I swipe left

Swiping a scroll view by index/number (and offset), or accessibilityLabel

    Then I swipe left on number 2
    Then I swipe left on number 2 at x 20 and y 10
    Then I swipe left on "accLabel"

Swiping table cells, by number

    Then I swipe on cell number 2

Pinch (for zooms)
---------------------------
This step makes a small pinch to zoom in or out. Either at the first scroll view of the screen, or a the center of a view with a certain accessibility label.

    Then I pinch to zoom in
    Then I pinch to zoom in on "accLabel"

Scrolling
---------
Scrolling on scroll views. Direction can be left, right, up or down.

    Then I scroll down
    Then I scroll down on "accLabel"


Playback of touch events
------------------------
If you have recorded a touch event sequence as "mytouch" you can playback those using

    Then I playback recording "mytouch"
    Then I playback recording "mytouch on "accLabel"
    Then I playback recording "mytouch on "accLabel" with offset 10,22

Device orientation
------------------
You can rotate the device or simulator left or right.

    Then I rotate device left

(when using the LessPainful which runs physical devices, this step is implemented by performing an actual physical rotation of the device using our little robots :)

Assertions
----------
Like waiting, these are usually about seeing certain text or ui components. Usually these are identified by their accessibilityLabels, component type (like a navigation bar) or pure text like in a label or a web view.

If the thing being asserted doesn't exist in the view, the test will fail.

Asserting existence of text, or a view with a certain accessibilityLabel

    Then I should see "text or label"
    Then I should not see "text or label"
    Then I see the text "some text"
    Then I don't see the text "text or label"
    Then I don't see the "someview"
    Then I see the "someview"

Asserting existence of buttons:

    Then I should see a "login" button
    Then I should not see a "login" button

More on text, prefix, suffix, and sub string.

    Then I should see text starting with "prefix"
    Then I should see text containing "sub text"
    Then I should see text ending with "suffix"

Seeing some text fields

    Then I see 2 input fields
    Then I should see a "Username" input field
    Then I should not see a "Username" input field


Seeing maps and user location

    Then I should see a map
    Then I should see the user location

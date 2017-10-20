@keyboard
Feature: Keyboard

Background: App has launched
Given the app has launched
And I am looking at the Text Input page
And the text field and question label are reset
And the return key type of the text field is "Done"

Scenario: Keyboard must be visible
When I try to type without the keyboard
Then a keyboard-not-visible error is raised

Scenario: Entering text with the keyboard
When I touch the text field
Then the keyboard is visible
When I type "Bien"
Then what I typed appears in the red box

Scenario: Text with single quotes
Given I typed "Gut, und du? Wie geht's?"
Then what I typed appears in the red box

Scenario: Deleting text with \b
Given I typed "Dangge, guet, und dir?"
And I decide I should be more formal
Then I replace "dir?" with "Ihre?" by sending backspace

Scenario: Deleting text by touching delete key
Given I typed "Tack, bra."
And I decide I want to be more emphatic
Then I replace "." with "!" using the delete key

Scenario: Entering text with keyboard_enter_char
Given I type "Fine" character by character
Then what I typed appears in the red box

Scenario: Entering text with enter_text method
Then I use enter_text to enter "Great!"
And what I typed appears in the red box

Scenario: Entering text with fast_enter_text method
When I touch the text field
Then the keyboard is visible
And I use fast_enter_text to enter "ik ben in orde"
Then what I typed appears in the red box

Scenario: Dismissing iPad keyboard
When I touch the text field
Then I can dismiss the keyboard on an iPad

Scenario: Touching the keyboard action key
And the return key type of the text field is "Return"
When I touch the text field I see the correct return key
And I can dismiss the keyboard with the action key
And I can dismiss a keyboard with a "Go" key
And I can dismiss a keyboard with a "Google" key
And I can dismiss a keyboard with a "Join" key
And I can dismiss a keyboard with a "Next" key
And I can dismiss a keyboard with a "Route" key
And I can dismiss a keyboard with a "Search" key
And I can dismiss a keyboard with a "Send" key
And I can dismiss a keyboard with a "Yahoo" key
And I can dismiss a keyboard with a "Done" key
And I can dismiss a keyboard with a "Emergency call" key
And I can dismiss a keyboard with a "Continue" key

Scenario: Dismissing keyboard by sending "\n"
And the return key type of the text field is "Done"
When I touch the text field I see the correct return key
Then I can dismiss the keyboard by sending a newline

Scenario: API tests
When the keyboard is showing, I can ask for the first responder text
And the keyboard is not showing, asking for the first responder text raises an error
When UIA is available, I can use it to check for keyboards
When UIA is not available, checking for keyboards with UIA raises an error
When the keyboard is not visible expect_keyboard_visible! raises an error
When the keyboard is visible expect_keyboard_visible! does not raise an error
And I can dismiss the keyboard with the action key

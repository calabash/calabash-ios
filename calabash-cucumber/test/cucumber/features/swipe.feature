@swipe
@pan
Feature: Swipe
In order to swipe between pages, swipe to delete, and move around scrolling views
As an iOS UI tester
I want a swipe API


Background: Navigate to Pan page
Given the app has launched
And I am looking at the Pan tab

# Restart after because this Scenario might leave a blocking iOS OS view
#@restart_after
@wip
Scenario: Full Screen Pan
And I am looking at the Pan Palette page
Then I can swipe to go back to the Pan menu
#Then I can swipe down to see the Today and Notifications page
#Then I can swipe to go back to the Pan menu
#Then I can swipe up to see the Control Panel page

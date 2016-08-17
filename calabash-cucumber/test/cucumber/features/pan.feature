@pan
Feature: Pan
In order to perform flicks, swipes, scrolls, and drag-and-drop
As an iOS UI tester
I want a pan API

Background: Navigate to Pan page
Given the app has launched
And I am looking at the Pan tab

# Restart after because this Scenario might leave a blocking iOS OS view
@restart_after
Scenario: Full Screen Pan
And I am looking at the Pan Palette page
Then I can pan to go back to the Pan menu
Then I can pull down to see the Today and Notifications page
Then I can pan to go back to the Pan menu
Then I can pull up to see the Control Panel page

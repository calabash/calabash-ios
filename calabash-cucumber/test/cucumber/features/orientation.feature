@orientation
Feature: Changing Orientation

Background: App has launched
Given the app has launched
And I am looking at the Touch tab

Scenario: Rotating around the home button
Then I rotate the device so the home button is on the top
Then I rotate the device so the home button is on the left
Then I rotate the device so the home button is on the right
Then I rotate the device so the home button is on the bottom

Scenario: Rotating left and right
Then I rotate the device so the home button is on the bottom
When I rotate the device to the left
Then the home button is on the right
Then I rotate the device so the home button is on the bottom
When I rotate the device to the right
Then the home button is on the left
Then I rotate the device so the home button is on the right
When I rotate the device to the right
Then the home button is on the bottom
Then I rotate the device so the home button is on the right
When I rotate the device to the left
Then the home button is on the top
Then I rotate the device so the home button is on the left
When I rotate the device to the left
Then the home button is on the bottom
Then I rotate the device so the home button is on the left
When I rotate the device to the right
Then the home button is on the top

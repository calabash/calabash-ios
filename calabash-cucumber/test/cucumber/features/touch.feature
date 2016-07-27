@touch
Feature: Touch

Background: App has launched
Given the app has launched
Given I am looking at the Tao tab

Scenario: Touch in any orientation
Given I am looking at the Tao tab
And I rotate the device so the home button is on the bottom
When the home button is on the bottom, I can touch
When the home button is on the right, I can touch
When the home button is on the left, I can touch
When the home button is on the top, I can touch

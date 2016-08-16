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

Scenario: Double tap in any orientation
Given I am looking at the Tao tab
When the home button is on the bottom, I can double tap
When the home button is on the right, I can double tap
When the home button is on the left, I can double tap
When the home button is on the top, I can double tap

Scenario: Long press durations
Given I am looking at the Tao tab
Then I long press a little button for a short time
Then I long press a little button for enough time
Then I long press a little button for a long time

Scenario: Long press in any orientation
Given I am looking at the Tao tab
When the home button is on the top, I can long press
When the home button is on the right, I can long press
When the home button is on the left, I can long press
When the home button is on the bottom, I can long press

Scenario: Two finger tap in any orientation
Given I am looking at the Tao tab
When the home button is on the left, I can two-finger tap
When the home button is on the top, I can two-finger tap
When the home button is on the right, I can two-finger tap
When the home button is on the bottom, I can two-finger tap

Scenario: Touch by point
And I rotate the device so the home button is on the bottom
Then I can touch by coordinate

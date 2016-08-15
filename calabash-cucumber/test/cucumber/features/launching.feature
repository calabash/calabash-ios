@launching
Feature:
In order to test my app shutting down and restarting
As an iOS Tester
I want some way to control when my app is restarted

Scenario: 00 Launch the app.
Given the app has launched
And I am looking at the Tao tab

Scenario: 01 App does not restart if it is already running
Then the app has launched
Then I see the Tao page

@restart_before
Scenario: 02 Restarting before the Scenario
Given the app has launched
Then I see the Touch page
And I am looking at the Tao tab

Scenario: 03 App does not restart if it is already running
Given the app has launched
Then I see the Tao page

@restart_after
Scenario: 04 Restarting after the Scenario: 1 of 2
Then the app has launched
Then I see the Tao page

Scenario: 05 Restarting after the Scenario: 2 of 2
Then the app has launched
Then I see the Touch page
And I am looking at the Tao tab

Scenario: 05 App does not restart if it is already running
Then the app has launched
Then I see the Tao page

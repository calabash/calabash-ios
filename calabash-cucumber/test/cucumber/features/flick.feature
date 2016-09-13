@pan
@flick
Feature: Flick
In order to move around views quickly
As an iOS UI Tester
I want a flick API

Background: Navigate to Pan page
Given the app has launched
And I am looking at the Pan tab

Scenario: Up, Down, Left, and Right Flicks
And I am looking at the Scrollplications page
Then I center the cayenne box to the middle
Then I flick so I can see the top of the scroll view
And I flick so I can see the bottom of the scroll view
Then I center the cayenne box to the middle
Then I flick so I can see the right of the scroll view
Then I flick so I can see the left of the scroll view

Scenario: Diagonal Flicks
And I am looking at the Scrollplications page
Then I center the cayenne box to the middle
Then I flick to the top right of the scroll view
And I flick to the bottom left of the scroll view
Then I center the cayenne box to the middle
Then I flick to the bottom right of the scroll view
Then I flick to the top left of the scroll view

Scenario: Flick to Go Back in UINavigationController
And I am looking at the Scrollplications page
When I full-screen flick to go back, I see the Pan menu
But flick to go back does not work with DeviceAgent

Scenario: Flicking on a Table View
And I am looking at the Everything's On the Table page
Given I see the Apple row
Then I can flick to the bottom of the Companies table
Then I can flick to the top of the Companies table

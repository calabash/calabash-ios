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
@wip
Scenario: Full Screen Pan
And I am looking at the Pan Palette page
Then I can swipe to go back to the Pan menu

@wip
Scenario: Swipe to Delete Table Cell
Given I am looking at the Everything's On the Table page
And I swipe to delete the 'Amazon' table cell
Then I no longer see the 'Amazon' table cell 

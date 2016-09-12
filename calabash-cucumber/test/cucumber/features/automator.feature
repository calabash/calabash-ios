@automator
Feature: Automator
In order to transition from UIAutomation to DeviceAgent
As a UI tester
I want a DeviceAgent API that can replace Calabash UIA methods

Background: Application is launched
Given the app has launched

Scenario: Querying UIA and DeviceAgent
And I am looking at the Touch tab
Then I query for the Silly Alpha button by mark using id
Then I query for the Silly Zero button by mark using the title
Then UIA and DeviceAgent can find views that are hidden
Then UIA and DeviceAgent results can be filtered by visibility
Then I can query by text
And I am looking at the Misc tab
Then I query for Same as views by mark using id
Then I query for Same as views by mark using id and filter by TextField
Then I query for Same as views by mark using id and filter by TextView
Then I query for Same as views by mark using id and use an index to find the Button

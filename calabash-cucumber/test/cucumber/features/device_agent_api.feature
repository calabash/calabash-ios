@device_agent
Feature: DeviceAgent API
  In order to interact with views that are outside of my application
  As a UI tester
  I want a DeviceAgent API

Background: Application is launched
Given the app has launched

Scenario: Screenshot on failure
When device_agent.query_for_coordinate fails, it generates a screenshot
When device_agent.touch fails, it generates a screenshot
When device_agent.double_tap fails, it generates a screenshot
When device_agent.two_finger_tap fails, it generates a screenshot
When device_agent.long_press fails, it generates a screenshot
When device_agent.enter_text fails, it generates a screenshot
When device_agent.enter_text_in fails, it generates a screenshot

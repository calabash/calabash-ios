@screenshot_and_raise
@issue_246
Feature:  Screenshot and raise
  In order to delight calabash clients all the world round
  As a calabash developer
  I want to take screenshots and raise exceptions

  Scenario: screenshot_and_raise in the context of cucumber
    When I use screenshot_and_raise in the context of cucumber
    Then I should get a runtime exception

  Scenario: screenshot_and_raise outside the context of cucumber
    When I screenshot_and_raise outside the context of cucumber
    Then I should get a runtime exception
    But it should not be a NoMethod exception for embed

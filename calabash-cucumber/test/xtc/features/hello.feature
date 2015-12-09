Feature: Type Hello

Background: Navigate to the controls tab
  Given I see the controls tab

@travis
Scenario: I should be able to type something
  Then I type "Hello"


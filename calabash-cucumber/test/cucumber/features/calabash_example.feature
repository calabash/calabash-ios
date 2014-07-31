Feature: some smoke tests

  Background: I should see the first view
    Given I see the first view

  Scenario: I should be able to type something
    Then I type "Hello"

Feature: to reset or not reset

  Background: I should see the first view
    Given I see the first view

  Scenario: I should be able to type something
    Then I type "Hello"

  @minitest
  Scenario: Try to reproduce the minitest problem by calling an operations method
    Then I use the operations module method labels

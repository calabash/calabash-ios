Feature: to reset or not reset

  Background: I should see the first view
    Given I see the first view

  @reset_app_before_hook
  Scenario: Use a Before hook to reset the app and then call the device function
    Then I should be able call the device function

  @reset_simulator_before_hook
  Scenario: Use a Before hook to reset the simulator and then type some text
    Then I type "Hello"

  @wip
  Scenario: Try to reproduce the minitest problem by calling an operations method
    Then I use the operations module method labels

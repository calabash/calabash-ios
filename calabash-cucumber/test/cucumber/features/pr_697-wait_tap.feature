@wait_tap
Feature: Wait, then tap. wait_tap

Scenario: wait_tap
  Given I see the first view
  And I make a note of the switch state
  When I tap the switch with wait_tap
  Then I see the switch in the new state


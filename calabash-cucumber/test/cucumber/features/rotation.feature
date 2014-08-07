Feature:  rotating the device

  Scenario: should be able to rotate to the home position
    Then I rotate the device 4 times in a random direction
    Then I rotate the device so the home button is on the bottom
    Then the orientation of the status bar and device should be same
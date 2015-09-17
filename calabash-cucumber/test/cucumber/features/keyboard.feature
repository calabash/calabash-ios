@keyboard
Feature: Keyboard Interactions

Background: Looking at the first view
  Given I see the first view

@typing
Scenario: I can type
  Then I type "Hello"

@rotation
Scenario: I can detect docked keyboards
  Given the keyboard is showing
  And if I am testing an iPad, the keyboard is docked
  Then I rotate the device so the home button is on the bottom
  Then I see a docked keyboard
  Then I rotate the device so the home button is on the left
  Then I see a docked keyboard
  Then I rotate the device so the home button is on the right
  Then I see a docked keyboard
  Then I rotate the device so the home button is on the top
  Then I see a docked keyboard

@rotation
Scenario: I can detect undocked keyboards
  Given the keyboard is showing
  And if I am testing an iPad, the keyboard is undocked
  Then I rotate the device so the home button is on the bottom
  Then I see a undocked keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the left
  Then I see a undocked keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the right
  Then I see a undocked keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the top
  Then I see a undocked keyboard if I am testing an iPad
  And I can dock the keyboard

@rotation
Scenario: I can detect undocked keyboards
  Given the keyboard is showing
  And if I am testing an iPad, the keyboard is split
  Then I rotate the device so the home button is on the bottom
  Then I see a split keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the left
  Then I see a split keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the right
  Then I see a split keyboard if I am testing an iPad
  Then I rotate the device so the home button is on the top
  Then I see a split keyboard if I am testing an iPad
  And I can dock the keyboard


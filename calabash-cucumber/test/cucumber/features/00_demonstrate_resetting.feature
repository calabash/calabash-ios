@resetting
Feature:  can persist a keychain item over app restart

  Background: I am on the first view
    Given I see the first view

  # Demonstrate that the keychain API works.
  @keychain
  Scenario: 00 I set the keychain item
    Given that the keychain contains the account password "pa$$w0rd" for "clever_user98"

  @keychain
  Scenario: 01 I should see the keychain item exists in the next Scenario
    Then the keychain should contain the account password "pa$$w0rd" for "clever_user98"
    When I clear the keychain
    Then the keychain should be empty

  # Demonstrate that resetting the simulator content and settings works using
  # the keychain as proxy.
  #
  # NOTE: Keychain items _persist_ over app resets (at least on the simulator),
  # which is surprising.
  @keychain
  @reset_simulator
  Scenario: 10 I set the keychain item
    Given that the keychain contains the account password "pa$$w0rd" for "clever_user98"

  @keychain
  @reset_simulator
  Scenario: 11 I should see the keychain item exists because I did not reset the simulator before this Scenario
    Then the keychain should contain the account password "pa$$w0rd" for "clever_user98"

  @keychain
  @reset_simulator
  @reset_simulator_before_hook
  Scenario: 12 The keychain should be empty because I reset the simulator content before this Scenario
    Then the keychain should be empty

  # Demonstrate that resetting the app works using NSUserDefaults as proxy.  The
  # on/off state of the switch on the first view is persisted in NSUserDefaults.
  #
  # NSUserDefaults are part of the app sandbox and so are deleted by
  # `reset_app_sandbox`.
  #
  # NOTE: Keychain items _persist_ over app resets (at least on the simulator),
  # which is surprising.
  @user_defaults
  @reset_app_btw_scenarios
  Scenario: 20 I turn the switch on the first view on
    Given I turn the switch on

  @user_defaults
  @reset_app_btw_scenarios
  Scenario: 21 The switch should be on because I did not reset the app before this Scenario
    Then I should see the switch is on

  @user_defaults
  @reset_app_btw_scenarios
  @reset_app_before_hook
  Scenario: 22 The switch should be off because I did reset the app before this Scenario
    Then I should see the switch is off
module Calabash
  module Cucumber
    module KeychainSteps
      def lp_keychain_service_name
        'lp.simple.example.service'
      end

      def qstr_for_switch
        "view marked:'first page' switch marked:'switch'"
      end

      def switch_state
        qstr = qstr_for_switch
        res = nil
        wait_for do
          res = query(qstr, :isOn).first
          not res.nil?
        end
        res == '1'
      end
    end
  end
end

World(Calabash::Cucumber::KeychainSteps)

When(/^I clear the keychain$/) do
  keychain_clear_accounts_for_service(lp_keychain_service_name)
end

Given(/^that the keychain is clear$/) do
  keychain_clear_accounts_for_service(lp_keychain_service_name)
end

Then(/^the keychain should contain the account password "(.*?)" for "(.*?)"$/) do |password, username|
  actual = keychain_password(lp_keychain_service_name, username)
  if xamarin_test_cloud?
    if actual.nil?
      screenshot_and_raise "expected an entry for '#{username}' in the keychain"
    end
  else
    unless actual == password
      screenshot_and_raise "expected '#{password}' in keychain but found '#{actual}'"
    end
  end
end

Given(/^that the keychain contains the account password "(.*?)" for "(.*?)"$/) do |password, username|
  # app uses the first account/password pair it finds, so clear out
  # any preexisting saved passwords for our service
  keychain_clear_accounts_for_service(lp_keychain_service_name)
  keychain_set_password(lp_keychain_service_name, username, password)
end

Then(/^the keychain should be empty$/) do
  accounts = keychain_accounts_for_service(lp_keychain_service_name)
  unless accounts.empty?
    raise "expected no accounts but found '#{accounts}'"
  end
end

Given(/^I turn the switch on$/) do
  wait_for_element_exists qstr_for_switch
  sleep(1.0) if uia_not_available?
  unless switch_state
    touch qstr_for_switch
    sleep(0.4)
  end

  unless switch_state
    screenshot_and_raise 'expected switch to be on'
  end
end

Then (/^I should see the switch is (on|off)$/) do |state|
  actual_state = switch_state ? 'on' : 'off'
  unless actual_state == state
    screenshot_and_raise "expected switch to be '#{state}' but found '#{actual_state}'"
  end
end

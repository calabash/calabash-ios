module Calabash
  module IOS
    module KeychainSteps
      def lp_keychain_service_name
        'lp.simple.example.service'
      end
    end
  end
end

World(Calabash::IOS::KeychainSteps)

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

module Calabash
  module IOS
    module ResetBetweenScenarioSteps
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
        res == 1
      end

      def add_file_to_sandbox_dir(filename, directory)
        arg = JSON.generate({'directory' => directory, 'filename' => filename})
        res = backdoor('addFileToSandboxDirectory:', arg)
        unless res
          raise "expected backdoor call to write '#{filename}' in '#{directory}'"
        end
      end

      def expect_file_in_sandbox_dir(filename, directory)
        res = backdoor('arrayForFilesInSandboxDirectory:', directory)
        if res.nil?
          raise "expected backdoor to return files for '#{directory}'"
        end

        unless res.include?(filename)
          raise "expected to see '#{filename}' in '#{res}'"
        end
      end

      def expect_file_does_not_exist_in_directory(filename, directory)
        res = backdoor('arrayForFilesInSandboxDirectory:', directory)
        if res.nil?
          raise "expected backdoor to return files for '#{directory}'"
        end

        if res.include?(filename)
          raise "expected not to see '#{filename}' in '#{res}'"
        end
      end
    end
  end
end

World(Calabash::IOS::ResetBetweenScenarioSteps)

Given(/^I turn the switch on$/) do
  wait_for_element_exists qstr_for_switch
  unless switch_state
    # having a very hard time touching this switch. :(
    # wait_tap does work. :(
    sleep(1.0)
    touch qstr_for_switch
    sleep(0.5)

    # trying to debug iOS 8 NSUserDefaults problem.
    # http://www.screencast.com/t/dxwNbDxn0Dp
    #
    # The gist is that when running with the instruments tool, NSUserDefaults
    # do not appear to be persisted.
    #
    # This does not help either.
    # wait_for_none_animating
    # send_app_to_background(2.0)
    #
    # Both of these and the 'touch' above can cause the switch to change state
    # and trigger a UIEvent.  However, none of them persist changes to
    # NSUserDefaults despite the Objc code on the app side demonstrating that
    # the defaults have been written.
    # uia("target.frontMostApp().mainWindow().elements()['first page'].switches()['switch'].tap()")
    # uia("target.frontMostApp().mainWindow().elements()['first page'].switches()['switch'].setValue(1)")
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

Then(/I make a note of the switch state$/) do
  @previous_switch_state = switch_state
end

And(/^I drop some files in the sandbox$/) do
  ['tmp', 'Documents', 'Library'].each do |dir|
    add_file_to_sandbox_dir('foo.txt', dir)
  end
end

Then(/^I should see the files I put in the sandbox$/) do
  ['tmp', 'Documents', 'Library'].each do |dir|
    expect_file_in_sandbox_dir('foo.txt', dir)
  end
end

Then(/^I should not see the files I put in the sandbox$/) do
  ['tmp', 'Documents', 'Library'].each do |dir|
    expect_file_does_not_exist_in_directory('foo.txt', dir)
  end

end

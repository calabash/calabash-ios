Then(/^I type "([^"]*)"$/) do |text_to_type|
  wait_for_element_exists('textField', {:post_timeout => 0.4})
  sleep 1.0 if uia_not_available?
  touch 'textField'
  sleep 0.4 if uia_not_available?
  wait_for_keyboard
  keyboard_enter_text text_to_type
end

Given(/^the keyboard is showing$/) do
  query = 'textField'
  options = wait_options(query)

  wait_for_element_exists(query, options)
  touch query
  wait_for_keyboard
end

Then(/^I see a docked keyboard$/) do
  expect(docked_keyboard_visible?).to be_truthy
end

Then(/^I see a undocked keyboard if I am testing an iPad$/) do
  if ipad?
    if ios9?
      expect(docked_keyboard_visible?).to be_truthy
    else
      expect(undocked_keyboard_visible?).to be_truthy
    end
  end
end

Then(/^I see a split keyboard if I am testing an iPad$/) do
  if ipad?
    if ios9?
      expect(docked_keyboard_visible?).to be_truthy
    else
      expect(split_keyboard_visible?).to be_truthy
    end
  end
end

And(/^if I am testing an iPad, the keyboard is docked$/) do
  ensure_docked_keyboard if ipad?
end

And(/^if I am testing an iPad, the keyboard is undocked$/) do
  if ipad?
    if ios9?
      Luffa.log_warn("\n\niPad keyboard modes are not available on iOS 9\n")
      expect do
        ensure_undocked_keyboard
      end.to raise_error Calabash::Cucumber::KeyboardModeError,
      /Changing keyboard modes is not supported on iOS 9/
    else
      ensure_undocked_keyboard
    end
  end
end

And(/^if I am testing an iPad, the keyboard is split$/) do
  if ipad?
    if ios9?
      Luffa.log_warn("\n\nPad keyboard modes are not available on iOS 9\n")
      expect do
        ensure_split_keyboard
      end.to raise_error Calabash::Cucumber::KeyboardModeError,
      /Changing keyboard modes is not supported on iOS 9/
    else
      ensure_split_keyboard
    end
  end
end

And(/^I can dock the keyboard$/) do
  ensure_docked_keyboard
end


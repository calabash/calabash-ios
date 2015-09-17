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
    expect(undocked_keyboard_visible?).to be_truthy
  end
end

Then(/^I see a split keyboard if I am testing an iPad$/) do
  if ipad?
    expect(split_keyboard_visible?).to be_truthy
  end
end

And(/^if I am testing an iPad, the keyboard is docked$/) do
  ensure_docked_keyboard if ipad?
end

And(/^if I am testing an iPad, the keyboard is undocked$/) do
  ensure_undocked_keyboard if ipad?
end

And(/^if I am testing an iPad, the keyboard is split$/) do
  ensure_split_keyboard if ipad?
end

And(/^I can dock the keyboard$/) do
  ensure_docked_keyboard
end


Then(/^I should be able call the device function$/) do
  default_device()
end

Given(/^I see the first view$/) do
  wait_for_element_exists("view marked:'first page'")
end

Then /^I use the operations module method labels$/ do
  # defined in operations.rb - trying to force bad output
  label('*')
end

Then(/^I type "([^"]*)"$/) do |text_to_type|
  # wait_tap 'textField' fails here on _devices_ (ipad ios 7 landscape aka venus)
  wait_for_element_exists('textField')
  sleep 1.0 if uia_not_available?
  touch 'textField'
  sleep 0.4 if uia_not_available?
  wait_for_keyboard
  keyboard_enter_text text_to_type
end

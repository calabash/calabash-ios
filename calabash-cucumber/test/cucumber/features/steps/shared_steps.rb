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



Given(/^I see the (controls|gestures|scrolls|special|date picker) tab$/) do |tab|
  wait_for_elements_exist('tabBarButton')
  case tab
    when 'controls'
      index = 0
    when 'gestures'
      index = 1
    when 'scrolls'
      index = 2
    when 'special'
      index = 3
    when 'date picker'
      index = 4
  end
  touch("tabBarButton index:#{index}")
  expected_view = "#{tab} page"
  wait_for_elements_exist("view marked:'#{expected_view}'")
end

Then(/^I type "([^"]*)"$/) do |text_to_type|
  query = 'UITextField'
  options = wait_options(query)
  wait_for_element_exists(query, options)

  touch(query)
  wait_for_keyboard

  keyboard_enter_text text_to_type
end


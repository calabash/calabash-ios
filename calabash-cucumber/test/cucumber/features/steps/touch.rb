module TestApp
  module TouchGestures
    def wait_for_gesture_text(text, mark="gesture performed")
      query = "* marked:'#{mark}'"
      actual = wait_for_view(query).first["text"]
      if actual != text
        fail %Q[
Expected query:

#{query}

to return a view with the correct text:

  Actual: #{actual}
Expected: #{text}

]
      end
    end

    def clear_small_button_action_label
      query = "* marked:'small button action'"
      wait_for_view(query)
      touch(query)
      wait_for_gesture_text("CLEARED", "small button action")
    end

    def clear_complex_button_action_label
      query = "* marked:'complex touches'"
      wait_for_view(query)
      touch(query)
      wait_for_gesture_text("CLEARED", "complex touches")
    end
  end
end

World(TestApp::TouchGestures)

And(/^I clear the touch action label$/) do
  clear_small_button_action_label
end

When(/^the home button is on the (top|right|left|bottom), I can (double tap|touch)$/) do |position, gesture|
  rotate_home_to_and_expect(position)
  if gesture == "double tap"
    query = "* marked:'double tap'"
    wait_for_view(query)
    double_tap(query)
    wait_for_gesture_text("double tap", "small button action")
  else
    query = "* marked:'touch'"
    wait_for_view(query)
    touch(query)
    wait_for_gesture_text("touch", "small button action")
  end
  clear_small_button_action_label
end

Then(/^I long press a little button for (a short|a long|enough) time$/) do |time|
  clear_small_button_action_label
  expected_text = "long press"

  if time == "a short"
    duration = 0.5
    expected_text = "CLEARED"
  elsif time == "a long"
    duration = 2.0
  elsif time == "enough"
    duration = 1.1
  end

  query = "* marked:'long press'"
  wait_for_view(query)

  touch_hold(query, {:duration => duration})
  wait_for_gesture_text(expected_text, "small button action")
end

When(/^the home button is on the (top|right|left|bottom), I can long press$/) do |position|
  clear_small_button_action_label
  rotate_home_to_and_expect(position)
  query = "* marked:'long press'"
  wait_for_view(query)
  touch_hold(query, {:duration => 1.1})
  wait_for_gesture_text("long press", "small button action")
  clear_small_button_action_label
end

When(/^the home button is on the (top|right|left|bottom), I can two-finger tap$/) do |position|
  rotate_home_to_and_expect(position)
  query = "* marked:'two finger tap'"
  wait_for_view(query)
  two_finger_tap(query)
  wait_for_gesture_text("two-finger tap", "complex touches")
  clear_complex_button_action_label
end


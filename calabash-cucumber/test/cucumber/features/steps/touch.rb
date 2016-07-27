module UnitTestApp
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

World(UnitTestApp::TouchGestures)

And(/^I clear the touch action label$/) do
  clear_small_button_action_label
end

When(/^the home button is on the (top|right|left|bottom), I can (double tap|touch)$/) do |position, gesture|
  rotate_home_to_and_expect(position)
  if gesture == "double tap"
    raise "Not implemented yet"
  else
    query = "* marked:'touch'"
    wait_for_view(query)
    touch(query)
    wait_for_gesture_text("touch", "small button action")
  end
  clear_small_button_action_label
end

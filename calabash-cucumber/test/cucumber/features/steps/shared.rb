module TestApp
  module Shared

    def wait_for_text_in_view(text, mark)
      query = "* marked:'#{mark}'"
      actual = wait_for_view(query)["text"]
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

  end
end

World(TestApp::Shared)

Given(/^the app has launched$/) do
  wait_for do
    !query("*").empty?
  end

  if keyboard_visible?
    ['textField', 'textView'].each do |ui_class|
      query = "#{ui_class} isFirstResponder:1"
      if !query(query).empty?
        query(query, :resignFirstResponder)
      end
    end

    wait_for_no_keyboard
  end
end

Given(/^I am looking at the (Touch|Pan|Rotate\/Pinch|Misc|Tao) tab$/) do |tabname|
  query = "* marked:'#{tabname}'"
  wait_for_view(query)
  touch(query)
  wait_for_view("* marked:'#{tabname.downcase} page'")
  wait_for_none_animating
end

Then(/^I see the (Touch|Pan|Rotate\/Pinch|Misc|Tao) page$/) do |page|
  wait_for_none_animating
  wait_for_view("* marked:'#{page.downcase} page'")
end

Given(/^I am looking at the Drag and Drop page$/) do
  query = "* marked:'drag and drop row'"
  wait_for_view(query)
  touch(query)
  wait_for_view("* marked:'drag and drop page'")
end

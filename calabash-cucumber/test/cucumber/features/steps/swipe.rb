Then(/^I can swipe to go back to the Pan menu$/) do
  swipe(:left)
  wait_for_animations
  wait_for_view("* marked:'pan page'")
end
